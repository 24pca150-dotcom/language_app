<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\PackageController;

Route::apiResource('packages', PackageController::class);

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');
