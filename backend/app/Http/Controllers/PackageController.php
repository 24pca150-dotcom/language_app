<?php

namespace App\Http\Controllers;

use App\Models\Package;
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
}
