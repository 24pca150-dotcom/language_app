<?php

namespace App\Http\Controllers;

use App\Models\CoursePackageLevel;
use App\Models\Level;
use Illuminate\Http\Request;

class CoursePackageLevelController extends Controller
{
    /**
     * List all levels mapped to a package, optionally filtered by course.
     */
    public function index($packageId, Request $request)
    {
        $query = CoursePackageLevel::where('package_id', $packageId);

        if ($request->has('course_id')) {
            $query->where('course_id', $request->course_id);
        }

        $levelIds = $query->pluck('level_id');

        $levels = Level::query()
            ->whereIn('id', $levelIds)
            ->orderBy('sort_order')
            ->get();

        return response()->json($levels);
    }

    /**
     * Map level(s) to a package — accepts array of level_ids and course_id.
     */
    public function store(Request $request, $packageId)
    {
        $validated = $request->validate([
            'course_id' => 'required|exists:courses,id',
            'level_ids' => 'required|array|min:1',
            'level_ids.*' => 'required|exists:levels,id',
            'is_mandatory' => 'nullable|boolean'
        ]);

        $created = [];
        foreach ($validated['level_ids'] as $levelId) {
            $mapping = CoursePackageLevel::updateOrCreate(
                [
                    'package_id' => $packageId,
                    'course_id' => $validated['course_id'],
                    'level_id' => $levelId
                ],
                [
                    'is_mandatory' => $validated['is_mandatory'] ?? true,
                    'is_active' => true
                ]
            );
            $created[] = $mapping;
        }

        return response()->json($created, 201);
    }

    /**
     * Remove a level mapping from a package.
     */
    public function destroy($packageId, $levelId)
    {
        CoursePackageLevel::where('package_id', $packageId)
            ->where('level_id', $levelId)
            ->delete();

        return response()->noContent();
    }
}
