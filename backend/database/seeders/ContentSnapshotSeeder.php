<?php

namespace Database\Seeders;

use App\Console\Commands\ContentSnapshot;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Loads database/seeders/data/content_snapshot.json (made with `php artisan content:snapshot`).
 *
 *   php artisan db:seed --class=ContentSnapshotSeeder
 *
 * Safe to run again: rows are matched by code (courses, levels, chapters, packages, tenants,
 * properties), activities by course + type + title, contents by name inside their chapter.
 * Existing rows are updated, missing ones created. Contents in the snapshot's chapters that are
 * not in the snapshot are removed, so the chapters end up exactly like the source.
 * File URLs are pointed at this server's APP_URL.
 */
class ContentSnapshotSeeder extends Seeder
{
    public function run(): void
    {
        $file = database_path('seeders/data/content_snapshot.json');
        if (!file_exists($file)) {
            $this->command?->error("Snapshot not found: {$file}. Run `php artisan content:snapshot` on the source first.");
            return;
        }

        $raw = str_replace(ContentSnapshot::URL_PLACEHOLDER, rtrim((string) config('app.url'), '/'), file_get_contents($file));
        $data = json_decode($raw, true, 512, JSON_THROW_ON_ERROR);
        $now = now();

        DB::transaction(function () use ($data, $now) {
            $upsert = function (string $table, array $key, array $values) use ($now): int {
                $existing = DB::table($table)->where($key)->first();
                if ($existing) {
                    DB::table($table)->where('id', $existing->id)->update($values + ['updated_at' => $now]);
                    return $existing->id;
                }
                return DB::table($table)->insertGetId($key + $values + ['created_at' => $now, 'updated_at' => $now]);
            };

            $tenantId = [];
            foreach ($data['tenants'] as $t) {
                $tenantId[$t['tenant_code']] = $upsert('tenants', ['tenant_code' => $t['tenant_code']], collect($t)->except('tenant_code')->all());
            }
            $propertyId = [];
            foreach ($data['properties'] as $p) {
                $values = collect($p)->except(['property_code', 'tenant_code'])->all() + ['tenant_id' => $tenantId[$p['tenant_code']] ?? null];
                $propertyId[$p['property_code']] = $upsert('properties', ['property_code' => $p['property_code']], $values);
            }

            $ids = [];
            foreach (['courses', 'levels', 'chapters', 'packages'] as $table) {
                foreach ($data[$table] as $row) {
                    $ids[$table][$row['code']] = $upsert($table, ['code' => $row['code']], collect($row)->except('code')->all());
                }
            }
            $id = fn (string $table, ?string $code) => $code === null ? null : ($ids[$table][$code] ?? null);

            foreach ($data['level_chapter'] as $r) {
                $upsert('level_chapter', ['level_id' => $id('levels', $r['level_code']), 'chapter_id' => $id('chapters', $r['chapter_code'])],
                    ['sort_order' => $r['sort_order'], 'is_active' => $r['is_active']]);
            }
            foreach ($data['course_package_levels'] as $r) {
                $upsert('course_package_levels', [
                    'course_id' => $id('courses', $r['course_code']),
                    'package_id' => $id('packages', $r['package_code']),
                    'level_id' => $id('levels', $r['level_code']),
                ], ['is_mandatory' => $r['is_mandatory'], 'is_active' => $r['is_active']]);
            }
            foreach ($data['property_packages'] as $r) {
                if (!isset($propertyId[$r['property_code']])) {
                    continue;
                }
                $upsert('property_packages', ['property_id' => $propertyId[$r['property_code']], 'package_id' => $id('packages', $r['package_code'])], [
                    'course_id' => $id('courses', $r['course_code']),
                    'learning_mode_ids' => $r['learning_mode_ids'],
                    'start_date' => $r['start_date'],
                    'end_date' => $r['end_date'],
                    'is_active' => $r['is_active'],
                ]);
            }

            // Activities: remember new ids so content blocks can point at them
            $activityId = [];
            foreach ($data['activities'] as $a) {
                $activityId[$a['snapshot_id']] = $upsert('activities', [
                    'course_id' => $id('courses', $a['course_code']),
                    'type' => $a['type'],
                    'title' => $a['title'],
                ], [
                    'cover_image' => $a['cover_image'],
                    'data_json' => $a['data_json'] === null ? null : json_encode($a['data_json'], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
                ]);
            }

            // Contents
            $keptByChapter = [];
            foreach ($data['contents'] as $c) {
                $chapters = collect($c['chapters'])->map(fn ($p) => ['chapter_id' => $id('chapters', $p['chapter_code']), 'sort_order' => $p['sort_order']])
                    ->filter(fn ($p) => $p['chapter_id'])->values();

                $text = $c['text_content'];
                $doc = $text ? json_decode($text, true) : null;
                if (is_array($doc) && isset($doc['blocks'])) {
                    foreach ($doc['blocks'] as &$block) {
                        $ref = $block['data']['activityReferenceId'] ?? null;
                        if (($block['type'] ?? '') === 'activity' && $ref && isset($activityId[$ref])) {
                            $block['data']['activityReferenceId'] = $activityId[$ref];
                        }
                    }
                    unset($block);
                    $text = json_encode($doc, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
                }

                $existing = DB::table('contents')
                    ->where('name', $c['name'])
                    ->when($chapters->isNotEmpty(), fn ($q) => $q->whereIn('id', DB::table('content_chapters')->whereIn('chapter_id', $chapters->pluck('chapter_id'))->select('content_id')))
                    ->first();
                $values = [
                    'title' => $c['title'],
                    'sort_order' => $c['sort_order'],
                    'is_active' => $c['is_active'],
                    'text_content' => $text,
                    'external_url' => $c['external_url'],
                ];
                if ($existing) {
                    DB::table('contents')->where('id', $existing->id)->update($values + ['updated_at' => $now]);
                    $contentId = $existing->id;
                } else {
                    $contentId = DB::table('contents')->insertGetId(['name' => $c['name']] + $values + ['created_at' => $now, 'updated_at' => $now]);
                }

                DB::table('content_chapters')->where('content_id', $contentId)->delete();
                foreach ($chapters as $p) {
                    DB::table('content_chapters')->insert([
                        'content_id' => $contentId, 'chapter_id' => $p['chapter_id'], 'sort_order' => $p['sort_order'],
                        'created_at' => $now, 'updated_at' => $now,
                    ]);
                    $keptByChapter[$p['chapter_id']][] = $contentId;
                }
            }

            // Remove contents that were deleted on the source (only inside the snapshot's chapters)
            $removed = 0;
            foreach ($ids['chapters'] ?? [] as $chapterId) {
                $stale = DB::table('content_chapters')->where('chapter_id', $chapterId)
                    ->whereNotIn('content_id', $keptByChapter[$chapterId] ?? [])->pluck('content_id');
                foreach ($stale as $contentId) {
                    DB::table('content_chapters')->where('content_id', $contentId)->where('chapter_id', $chapterId)->delete();
                    if (!DB::table('content_chapters')->where('content_id', $contentId)->exists()) {
                        DB::table('contents')->where('id', $contentId)->delete();
                        $removed++;
                    }
                }
            }

            $this->command?->info(sprintf(
                'Content snapshot loaded: %d courses, %d levels, %d chapters, %d contents, %d activities (%d old contents removed).',
                count($data['courses']), count($data['levels']), count($data['chapters']), count($data['contents']), count($data['activities']), $removed
            ));
        });
    }
}
