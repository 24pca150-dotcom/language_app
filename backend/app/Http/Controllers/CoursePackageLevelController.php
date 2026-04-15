<?php

namespace App\Http\Controllers;

use App\Models\CoursePackageLevel;
use App\Models\Level;
use Illuminate\Http\Request;

class CoursePackageLevelController extends Controller
{
    /**
     * List all levels mapped to a package.
     */
    public function index($packageId)
    {
        $mappings = CoursePackageLevel::where('package_id', $packageId)
            ->get()
            ->pluck('level_id');

        $levels = Level::with('course')
            ->whereIn('id', $mappings)
            ->orderBy('sort_order')
            ->get();

        return response()->json($levels);
    }

    /**
     * Map level(s) to a package — accepts array of level_ids.
     */
    public function store(Request $request, $packageId)
    {
        $validated = $request->validate([
            'level_ids' => 'required|array|min:1',
            'level_ids.*' => 'required|exists:levels,id',
        ]);

        $created = [];
        foreach ($validated['level_ids'] as $levelId) {
            $mapping = CoursePackageLevel::firstOrCreate(
                ['package_id' => $packageId, 'level_id' => $levelId],
                ['is_active' => true]
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
