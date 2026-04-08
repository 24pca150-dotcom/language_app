<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\PackageController;
use App\Http\Controllers\TenantController;
use App\Http\Controllers\PropertyController;

Route::apiResource('packages', PackageController::class);
Route::apiResource('tenants', TenantController::class);
Route::apiResource('properties', PropertyController::class);

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');
