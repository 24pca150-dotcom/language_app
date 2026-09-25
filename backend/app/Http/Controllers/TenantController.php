<?php

namespace App\Http\Controllers;

use App\Models\Tenant;
use Illuminate\Http\Request;

class TenantController extends Controller
{
    public function index(Request $request)
    {
        if ($request->user() && $request->user()->role !== 'super_admin') {
            return Tenant::where('id', $request->user()->tenant_id)->get();
        }
        return Tenant::orderBy('created_at', 'desc')->get();
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'tenant_code' => 'required|unique:tenants,tenant_code',
            'tenant_name' => 'required|string|max:255',
            'contact_person' => 'nullable|string|max:255',
            'email' => 'required|email|max:255',
            'phone' => 'nullable|string|max:20',
            'address' => 'nullable|string',
            'is_active' => 'boolean',
            'logo_path' => 'nullable|string',
            'primary_color' => 'nullable|string|max:10',
            'secondary_color' => 'nullable|string|max:10',
        ]);

        if ($request->hasFile('logo')) {
            $path = $request->file('logo')->store('logos', 'public');
            $validated['logo_path'] = asset('storage/' . $path);
        } elseif ($request->filled('logo_path') && str_starts_with($request->input('logo_path'), 'data:image')) {
            $image = $request->input('logo_path');
            if (preg_match('/^data:image\/(\w+);base64,/', $image, $type)) {
                $imageData = substr($image, strpos($image, ',') + 1);
                $ext = strtolower($type[1]) === 'jpeg' ? 'jpg' : strtolower($type[1]);
                $decoded = base64_decode($imageData);
                $fileName = 'logo_' . time() . '_' . uniqid() . '.' . $ext;
                \Illuminate\Support\Facades\Storage::disk('public')->put('logos/' . $fileName, $decoded);
                $validated['logo_path'] = asset('storage/logos/' . $fileName);
            }
        }

        return Tenant::create($validated);
    }

    public function show(Tenant $tenant)
    {
        return $tenant;
    }

    public function update(Request $request, Tenant $tenant)
    {
        $validated = $request->validate([
            'tenant_code' => 'required|unique:tenants,tenant_code,' . $tenant->id,
            'tenant_name' => 'required|string|max:255',
            'contact_person' => 'nullable|string|max:255',
            'email' => 'required|email|max:255',
            'phone' => 'nullable|string|max:20',
            'address' => 'nullable|string',
            'is_active' => 'boolean',
            'logo_path' => 'nullable|string',
            'primary_color' => 'nullable|string|max:10',
            'secondary_color' => 'nullable|string|max:10',
        ]);

        if ($request->hasFile('logo')) {
            $path = $request->file('logo')->store('logos', 'public');
            $validated['logo_path'] = asset('storage/' . $path);
        } elseif ($request->filled('logo_path') && str_starts_with($request->input('logo_path'), 'data:image')) {
            $image = $request->input('logo_path');
            if (preg_match('/^data:image\/(\w+);base64,/', $image, $type)) {
                $imageData = substr($image, strpos($image, ',') + 1);
                $ext = strtolower($type[1]) === 'jpeg' ? 'jpg' : strtolower($type[1]);
                $decoded = base64_decode($imageData);
                $fileName = 'logo_' . time() . '_' . uniqid() . '.' . $ext;
                \Illuminate\Support\Facades\Storage::disk('public')->put('logos/' . $fileName, $decoded);
                $validated['logo_path'] = asset('storage/logos/' . $fileName);
            }
        }

        $tenant->update($validated);
        return $tenant;
    }

    public function uploadLogo(Request $request, Tenant $tenant)
    {
        $request->validate([
            'logo' => 'required|image|mimes:jpeg,png,jpg,gif,svg,webp|max:2048',
        ]);

        $path = $request->file('logo')->store('logos', 'public');
        $logoUrl = asset('storage/' . $path);
        $tenant->update(['logo_path' => $logoUrl]);

        return response()->json([
            'message' => 'Logo uploaded successfully',
            'logo_url' => $logoUrl,
            'tenant' => $tenant
        ]);
    }

    public function destroy(Tenant $tenant)
    {
        $tenant->delete();
        return response()->noContent();
    }

    /**
     * Public endpoint to fetch tenant colors and logo URL by school/tenant code.
     */
    public function getBranding(string $code)
    {
        $tenant = Tenant::where('tenant_code', $code)
                        ->where('is_active', true)
                        ->first();

        if (!$tenant) {
            return response()->json(['error' => 'Institution code not found.'], 404);
        }

        return response()->json([
            'tenant_name' => $tenant->tenant_name,
            'logo_url' => $tenant->logo_path,
            'primary_color' => $tenant->primary_color ?: '#7c3aed',
            'secondary_color' => $tenant->secondary_color ?: '#db2777',
        ]);
    }

    /**
     * Public endpoint to fetch active tenants for selection on login/portal entry.
     */
    public function getPublicList()
    {
        return Tenant::where('is_active', true)
            ->select('id', 'tenant_code', 'tenant_name', 'logo_path', 'primary_color', 'secondary_color')
            ->orderBy('tenant_name', 'asc')
            ->get();
    }

    /**
     * Update branding options for a tenant.
     */
    public function updateBranding(Request $request, Tenant $tenant)
    {
        $user = $request->user();
        if (!$user || !in_array($user->role, ['super_admin', 'admin']) || ($user->role === 'admin' && $user->tenant_id !== $tenant->id)) {
            return response()->json(['error' => 'Unauthorized action.'], 403);
        }

        $validated = $request->validate([
            'primary_color' => 'nullable|string|max:10',
            'secondary_color' => 'nullable|string|max:10',
            'logo_path' => 'nullable|string',
        ]);

        if ($request->hasFile('logo')) {
            $path = $request->file('logo')->store('logos', 'public');
            $validated['logo_path'] = asset('storage/' . $path);
        }

        $tenant->update($validated);
        return response()->json($tenant);
    }
}
