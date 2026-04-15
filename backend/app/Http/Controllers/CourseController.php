<?php

namespace App\Http\Controllers;

use App\Models\Course;
use Illuminate\Http\Request;

class CourseController extends Controller
{
    public function index()
    {
        return response()->json(Course::with('levels')->latest()->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'no_of_levels' => 'required|integer|min:1',
            'description' => 'nullable|string',
            'is_active' => 'boolean',
        ]);

        $course = Course::create($validated);

        return response()->json($course->load('levels'), 201);
    }

    public function show(Course $course)
    {
        return response()->json($course->load('levels'));
    }

    public function update(Request $request, Course $course)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'no_of_levels' => 'required|integer|min:1',
            'description' => 'nullable|string',
            'is_active' => 'boolean',
        ]);

        $course->update($validated);

        return response()->json($course->load('levels'));
    }

    public function destroy(Course $course)
    {
        $course->delete();
        return response()->noContent();
    }
}
