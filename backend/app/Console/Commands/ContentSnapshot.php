<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * Exports the learning content (courses, levels, chapters, contents, activities, packages and their
 * mappings) to database/seeders/data/content_snapshot.json, so ContentSnapshotSeeder can load the same
 * content on another server. Records are matched by their codes, not ids. Users/progress are not exported.
 *
 *   php artisan content:snapshot
 */
class ContentSnapshot extends Command
{
    protected $signature = 'content:snapshot {--path= : Output file (default database/seeders/data/content_snapshot.json)}';

    protected $description = 'Export courses, levels, chapters, contents and activities to a JSON snapshot for ContentSnapshotSeeder';

    public const URL_PLACEHOLDER = '{{APP_URL}}';

    public function handle(): int
    {
        $courseCode = DB::table('courses')->pluck('code', 'id');
        $levelCode = DB::table('levels')->pluck('code', 'id');
        $chapterCode = DB::table('chapters')->pluck('code', 'id');
        $packageCode = DB::table('packages')->pluck('code', 'id');
        $tenantCode = DB::table('tenants')->pluck('tenant_code', 'id');
        $propertyCode = DB::table('properties')->pluck('property_code', 'id');

        $strip = fn ($row, array $drop = ['id', 'created_at', 'updated_at']) => collect((array) $row)->except($drop)->all();

        $snapshot = [
            'generated_at' => now()->toIso8601String(),
            'tenants' => DB::table('tenants')->orderBy('id')->get()->map(fn ($r) => $strip($r))->all(),
            'properties' => DB::table('properties')->orderBy('id')->get()->map(fn ($r) => $strip($r, ['id', 'tenant_id', 'created_at', 'updated_at'])
                + ['tenant_code' => $tenantCode[$r->tenant_id] ?? null])->all(),
            'courses' => DB::table('courses')->orderBy('id')->get()->map(fn ($r) => $strip($r))->all(),
            'levels' => DB::table('levels')->orderBy('id')->get()->map(fn ($r) => $strip($r))->all(),
            'chapters' => DB::table('chapters')->orderBy('id')->get()->map(fn ($r) => $strip($r))->all(),
            'packages' => DB::table('packages')->orderBy('id')->get()->map(fn ($r) => $strip($r))->all(),

            'level_chapter' => DB::table('level_chapter')->orderBy('id')->get()->map(fn ($r) => [
                'level_code' => $levelCode[$r->level_id] ?? null,
                'chapter_code' => $chapterCode[$r->chapter_id] ?? null,
                'sort_order' => $r->sort_order,
                'is_active' => $r->is_active,
            ])->all(),

            'course_package_levels' => DB::table('course_package_levels')->orderBy('id')->get()->map(fn ($r) => [
                'course_code' => $courseCode[$r->course_id] ?? null,
                'package_code' => $packageCode[$r->package_id] ?? null,
                'level_code' => $levelCode[$r->level_id] ?? null,
                'is_mandatory' => $r->is_mandatory,
                'is_active' => $r->is_active,
            ])->all(),

            'property_packages' => DB::table('property_packages')->orderBy('id')->get()->map(fn ($r) => [
                'property_code' => $propertyCode[$r->property_id] ?? null,
                'package_code' => $packageCode[$r->package_id] ?? null,
                'course_code' => $r->course_id ? ($courseCode[$r->course_id] ?? null) : null,
                'learning_mode_ids' => $r->learning_mode_ids,
                'start_date' => $r->start_date,
                'end_date' => $r->end_date,
                'is_active' => $r->is_active,
            ])->all(),

            // snapshot_id = local id, used only to re-link content blocks to the new activity ids
            'activities' => DB::table('activities')->orderBy('id')->get()->map(fn ($r) => [
                'snapshot_id' => $r->id,
                'course_code' => $r->course_id ? ($courseCode[$r->course_id] ?? null) : null,
                'title' => $r->title,
                'type' => $r->type,
                'cover_image' => $r->cover_image,
                'data_json' => json_decode($r->data_json ?? 'null', true),
            ])->all(),

            'contents' => DB::table('contents')->orderBy('id')->get()->map(fn ($r) => $strip($r) + [
                'chapters' => DB::table('content_chapters')->where('content_id', $r->id)->get()->map(fn ($p) => [
                    'chapter_code' => $chapterCode[$p->chapter_id] ?? null,
                    'sort_order' => $p->sort_order,
                ])->all(),
            ])->all(),
        ];

        $dupes = collect($snapshot['activities'])->groupBy(fn ($a) => $a['course_code'] . '|' . $a['type'] . '|' . $a['title'])->filter(fn ($g) => $g->count() > 1);
        if ($dupes->isNotEmpty()) {
            $this->warn('Activities with the same course + type + title (they will be merged on import): ' . $dupes->keys()->implode(', '));
        }

        $json = json_encode($snapshot, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

        // Make uploaded-file URLs server independent
        $hosts = array_unique(array_filter([rtrim((string) config('app.url'), '/'), 'http://127.0.0.1:8000', 'http://localhost:8000']));
        foreach ($hosts as $host) {
            $json = str_replace([$host, str_replace('/', '\\/', $host)], self::URL_PLACEHOLDER, $json);
        }

        $path = $this->option('path') ?: database_path('seeders/data/content_snapshot.json');
        if (!is_dir(dirname($path))) {
            mkdir(dirname($path), 0755, true);
        }
        file_put_contents($path, $json);

        $this->info('Snapshot written to ' . $path);
        foreach (['courses', 'levels', 'chapters', 'contents', 'activities', 'packages', 'tenants', 'properties'] as $k) {
            $this->line(sprintf('  %-11s %d', $k, count($snapshot[$k])));
        }
        $this->line('Uploaded files referenced by the content must also be copied to the server: storage/app/public/contents/');

        return self::SUCCESS;
    }
}
