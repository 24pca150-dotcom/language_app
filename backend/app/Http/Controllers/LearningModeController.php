<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\LearningMode;
use Illuminate\Http\Request;

class LearningModeController extends Controller
{
    public function index()
    {
        return response()->json(LearningMode::latest()->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:100',
            'code' => 'required|string|max:50|unique:learning_modes,code',
            'description' => 'nullable|string',
            'is_active' => 'boolean',
        ]);

        $learningMode = LearningMode::create($validated);

        return response()->json($learningMode, 201);
    }

    public function show(LearningMode $learningMode)
    {
        return response()->json($learningMode);
    }

    public function update(Request $request, LearningMode $learningMode)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:100',
            'code' => 'required|string|max:50|unique:learning_modes,code,' . $learningMode->id,
            'description' => 'nullable|string',
            'is_active' => 'boolean',
        ]);

        $learningMode->update($validated);

        return response()->json($learningMode);
    }

    public function destroy(LearningMode $learningMode)
    {
        $learningMode->delete();
        return response()->noContent();
    }
}
