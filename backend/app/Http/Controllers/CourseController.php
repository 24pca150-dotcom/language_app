<?php

namespace App\Http\Controllers;

use App\Models\Course;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CourseController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        $query = Course::query();

        if ($user && $user->role === 'student' && $user->tenant_id) {
            $today = now()->toDateString();
            $assignments = $this->activeAssignmentsForTenant($user->tenant_id, $today);

            $query->where('courses.is_active', true)
                ->whereIn('courses.id', (clone $assignments)->whereNotNull('pp.course_id')->select('pp.course_id')->distinct());

            $activeMappings = DB::table('course_package_levels as cpl')
                ->whereColumn('cpl.course_id', 'courses.id')
                ->where('cpl.is_active', true)
                ->whereIn('cpl.package_id', (clone $assignments)
                    ->whereColumn('pp.course_id', 'cpl.course_id')
                    ->select('pp.package_id'));
        } else {
            $activeMappings = DB::table('course_package_levels as cpl')
                ->whereColumn('cpl.course_id', 'courses.id')
                ->where('cpl.is_active', true);
        }

        $chapterMappings = (clone $activeMappings)
            ->join('levels as l', 'cpl.level_id', '=', 'l.id')
            ->join('level_chapter as lc', 'l.id', '=', 'lc.level_id')
            ->join('chapters as ch', 'lc.chapter_id', '=', 'ch.id')
            ->where('l.is_active', true)
            ->where('lc.is_active', true)
            ->where('ch.is_active', true);

        $query->addSelect([
            'levels_count' => (clone $activeMappings)->selectRaw('COUNT(DISTINCT cpl.level_id)'),
            'chapters_count' => $chapterMappings->selectRaw('COUNT(DISTINCT ch.id)'),
        ]);

        $courses = $query->latest()->get();
        $courses->each(function ($course) {
            if (isset($course->levels_count) && $course->levels_count > 0) {
                $course->no_of_levels = $course->levels_count;
            }
        });

        return response()->json($courses);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'is_active' => 'boolean',
        ]);

        $course = Course::create($validated);

        return response()->json($course, 201);
    }

    public function show(Course $course)
    {
        return response()->json($course);
    }

    public function update(Request $request, Course $course)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'is_active' => 'boolean',
        ]);

        $course->update($validated);

        return response()->json($course);
    }

    public function destroy(Course $course)
    {
        $course->delete();
        return response()->noContent();
    }
    public function getPlayerStructure(Course $course, Request $request)
    {
        $user = $request->user();
        $today = now()->toDateString();
        $tenantAssignments = $user && $user->role === 'student' && $user->tenant_id
            ? $this->activeAssignmentsForTenant($user->tenant_id, $today)
            : null;

        $structure = $course->load([
            'levels' => function ($query) use ($tenantAssignments) {
                $query->where('course_package_levels.is_active', true)
                    ->where('levels.is_active', true)
                    ->when($tenantAssignments, function ($query) use ($tenantAssignments) {
                        $query->whereIn(
                            'course_package_levels.package_id',
                            (clone $tenantAssignments)
                                ->whereColumn('pp.course_id', 'course_package_levels.course_id')
                                ->select('pp.package_id')
                        );
                    })
                    ->orderBy('levels.sort_order');
            },
            'levels.chapters' => function ($query) {
                $query->where('level_chapter.is_active', true)
                    ->where('chapters.is_active', true)
                    ->orderBy('chapters.sort_order')
                    ->orderBy('level_chapter.sort_order');
            },
            'levels.chapters.contents' => function ($query) {
                $query->select('contents.id', 'contents.name', 'contents.title', 'contents.sort_order', 'contents.is_active')
                    ->where('contents.is_active', true)
                    ->orderBy('contents.sort_order');
            },
            'levels.chapters.assessments' => function ($query) {
                $query->where('assessments.is_active', true);
            }
        ]);

        return response()->json($structure);
    }

    private function activeAssignmentsForTenant(int $tenantId, string $today)
    {
        return DB::table('property_packages as pp')
            ->join('properties as p', 'pp.property_id', '=', 'p.id')
            ->join('packages as pkg', 'pp.package_id', '=', 'pkg.id')
            ->where('p.tenant_id', $tenantId)
            ->where('p.is_active', true)
            ->where('pkg.is_active', true)
            ->where('pp.is_active', true)
            ->where(function ($query) use ($today) {
                $query->whereNull('pp.start_date')->orWhere('pp.start_date', '<=', $today);
            })
            ->where(function ($query) use ($today) {
                $query->whereNull('pp.end_date')->orWhere('pp.end_date', '>=', $today);
            })
            ->select(['pp.package_id', 'pp.course_id']);
    }
}
