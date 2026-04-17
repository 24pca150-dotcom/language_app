<?php

namespace App\Http\Controllers;

use App\Models\Level;
use Illuminate\Http\Request;

class LevelController extends Controller
{
    public function index(Request $request)
    {
        $query = Level::with('course');

        if ($request->has('course_id')) {
            $query->where('course_id', $request->course_id);
        }

        return response()->json($query->orderBy('sort_order')->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'course_id' => 'required|exists:courses,id',
            'name' => 'required|string|max:255',
            'code' => 'required|string|max:50|unique:levels,code',
            'description' => 'nullable|string',
            'objective_listening' => 'nullable|string',
            'objective_speaking' => 'nullable|string',
            'objective_reading' => 'nullable|string',
            'objective_writing' => 'nullable|string',
            'estimated_hours' => 'nullable|numeric|min:0',
            'sort_order' => 'nullable|integer|min:0',
            'is_active' => 'boolean',
        ]);

        $level = Level::create($validated);

        return response()->json($level->load('course'), 201);
    }

    public function show(Level $level)
    {
        return response()->json($level->load(['course', 'chapters.subChapters', 'assessments.questions.options']));
    }

    public function update(Request $request, Level $level)
    {
        $validated = $request->validate([
            'course_id' => 'required|exists:courses,id',
            'name' => 'required|string|max:255',
            'code' => 'required|string|max:50|unique:levels,code,' . $level->id,
            'description' => 'nullable|string',
            'objective_listening' => 'nullable|string',
            'objective_speaking' => 'nullable|string',
            'objective_reading' => 'nullable|string',
            'objective_writing' => 'nullable|string',
            'estimated_hours' => 'nullable|numeric|min:0',
            'sort_order' => 'nullable|integer|min:0',
            'is_active' => 'boolean',
        ]);

        $level->update($validated);

        return response()->json($level->load('course'));
    }

    public function destroy(Level $level)
    {
        $level->delete();
        return response()->noContent();
    }
}
