<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

use App\Models\Activity;
use Illuminate\Support\Facades\DB;

class ActivityController extends Controller
{
    public function index(Request $request)
    {
        $query = Activity::with('course:id,name,code');
        
        // Scope to tenant or global activities if applicable
        if ($request->user() && $request->user()->tenant_id) {
            $query->where(function ($q) use ($request) {
                $q->where('tenant_id', $request->user()->tenant_id)
                  ->orWhereNull('tenant_id');
            });
        }

        if ($request->has('ids') && $request->ids) {
            $ids = is_array($request->ids) ? $request->ids : explode(',', $request->ids);
            $query->whereIn('id', $ids);
        }

        if ($request->has('type') && $request->type) {
            $query->where('type', $request->type);
        }

        if ($request->has('course_id') && $request->course_id) {
            $query->where(function ($q) use ($request) {
                $q->where('course_id', $request->course_id)
                  ->orWhereNull('course_id');
            });
        }

        $activities = $query->latest()->get();

        // Activity Builder asks for the levels each activity is used in (costly: reads all contents)
        if ($request->boolean('with_levels')) {
            $levelMap = $this->activityLevelMap();
            $activities->each(function ($activity) use ($levelMap) {
                $activity->setAttribute('level_ids', $levelMap[$activity->id] ?? []);
            });
        }

        return response()->json($activities);
    }

    /**
     * Map activity id => level ids, following content (activity reference blocks) -> chapter -> level.
     */
    private function activityLevelMap(): array
    {
        $chapterLevels = DB::table('level_chapter')->get(['level_id', 'chapter_id'])
            ->groupBy('chapter_id')
            ->map(fn ($rows) => $rows->pluck('level_id')->all());

        $rows = DB::table('content_chapters')
            ->join('contents', 'contents.id', '=', 'content_chapters.content_id')
            ->get(['content_chapters.chapter_id', 'contents.text_content']);

        $map = [];
        foreach ($rows as $row) {
            $levels = $chapterLevels[$row->chapter_id] ?? [];
            if (!$levels || !$row->text_content) {
                continue;
            }
            $doc = json_decode($row->text_content, true);
            foreach (($doc['blocks'] ?? []) as $block) {
                $refId = $block['data']['activityReferenceId'] ?? null;
                if (($block['type'] ?? '') === 'activity' && $refId) {
                    $map[$refId] = array_values(array_unique(array_merge($map[$refId] ?? [], $levels)));
                }
            }
        }

        return $map;
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'type' => 'required|string',
            'cover_image' => 'nullable|string|max:1000',
            'course_id' => 'nullable|exists:courses,id',
            'data_json' => 'nullable|array',
        ]);

        if ($request->user() && $request->user()->tenant_id) {
            $validated['tenant_id'] = $request->user()->tenant_id;
        }
        $validated['created_by'] = $request->user()?->id;

        // No picture chosen -> use the game type's default cover (public/game-covers)
        if (empty($validated['cover_image'])) {
            $validated['cover_image'] = Activity::defaultCoverFor($validated['type']);
        }

        $activity = Activity::create($validated);
        $activity->load('course:id,name,code');

        return response()->json($activity, 201);
    }

    public function show(Request $request, $id)
    {
        $activity = Activity::with('course:id,name,code')->findOrFail($id);

        if ($request->user() && $request->user()->tenant_id && $activity->tenant_id && $activity->tenant_id !== $request->user()->tenant_id) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        return response()->json($activity);
    }

    public function update(Request $request, $id)
    {
        $activity = Activity::findOrFail($id);

        if ($request->user() && $request->user()->tenant_id && $activity->tenant_id && $activity->tenant_id !== $request->user()->tenant_id) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'title' => 'sometimes|required|string|max:255',
            'type' => 'sometimes|required|string',
            'cover_image' => 'nullable|string|max:1000',
            'course_id' => 'nullable|exists:courses,id',
            'data_json' => 'nullable|array',
        ]);

        // Cover cleared -> fall back to the game type's default picture (same as store())
        if (array_key_exists('cover_image', $validated) && empty($validated['cover_image'])) {
            $validated['cover_image'] = Activity::defaultCoverFor($validated['type'] ?? $activity->type);
        }

        $activity->update($validated);
        $activity->load('course:id,name,code');

        return response()->json($activity);
    }

    public function destroy(Request $request, $id)
    {
        $activity = Activity::findOrFail($id);

        if ($request->user() && $request->user()->tenant_id && $activity->tenant_id && $activity->tenant_id !== $request->user()->tenant_id) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $activity->delete();

        return response()->json(null, 204);
    }
}
