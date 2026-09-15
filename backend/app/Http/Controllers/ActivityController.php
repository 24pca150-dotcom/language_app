<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

use App\Models\Activity;

class ActivityController extends Controller
{
    public function index(Request $request)
    {
        $query = Activity::with('course:id,name,code');
        
        // Scope to tenant if applicable
        if ($request->user() && $request->user()->tenant_id) {
            $query->where(function ($q) use ($request) {
                $q->where('tenant_id', $request->user()->tenant_id)
                  ->orWhereNull('tenant_id');
            });
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

        return response()->json($query->latest()->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'type' => 'required|string',
            'course_id' => 'nullable|exists:courses,id',
            'data_json' => 'nullable|array',
        ]);

        if ($request->user() && $request->user()->tenant_id) {
            $validated['tenant_id'] = $request->user()->tenant_id;
        }
        $validated['created_by'] = $request->user()?->id;

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
            'course_id' => 'nullable|exists:courses,id',
            'data_json' => 'nullable|array',
        ]);

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
