<?php

namespace App\Http\Controllers;

use App\Models\Package;
use App\Models\Level;
use App\Models\CoursePackageLevel;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class PackageController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        return response()->json(Package::with('courses')->latest()->get());
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'required|string|max:255|unique:packages,code',
            'description' => 'nullable|string',
            'is_active' => 'required|boolean',
        ]);

        $package = Package::create($validated);

        return response()->json($package, 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(Package $package)
    {
        return response()->json($package);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, Package $package)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'required|string|max:255|unique:packages,code,' . $package->id,
            'description' => 'nullable|string',
            'is_active' => 'required|boolean',
        ]);

        $package->update($validated);

        return response()->json($package);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Package $package)
    {
        $package->delete();
        return response()->json(null, 204);
    }

    /**
     * List all levels mapped to a package, optionally filtered by course.
     */
    public function getLevels($packageId, Request $request)
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
    public function mapLevels(Request $request, $packageId)
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
    public function unmapLevel($packageId, $levelId)
    {
        CoursePackageLevel::where('package_id', $packageId)
            ->where('level_id', $levelId)
            ->delete();

        return response()->noContent();
    }
}
