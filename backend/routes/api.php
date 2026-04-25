<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\PackageController;
use App\Http\Controllers\TenantController;
use App\Http\Controllers\PropertyController;
use App\Http\Controllers\CourseController;
use App\Http\Controllers\LevelController;
use App\Http\Controllers\CoursePackageLevelController;
use App\Http\Controllers\ChapterController;
use App\Http\Controllers\AssessmentController;
use App\Http\Controllers\LearningProgressController;
use App\Http\Controllers\LearningModeController;

// Existing resources
Route::apiResource('packages', PackageController::class);
Route::apiResource('tenants', TenantController::class);
Route::apiResource('properties', PropertyController::class);

// New resources
Route::apiResource('courses', CourseController::class);
Route::apiResource('levels', LevelController::class);
Route::apiResource('chapters', ChapterController::class);
Route::apiResource('assessments', AssessmentController::class);
Route::apiResource('learning-modes', LearningModeController::class);

// Course-Package-Level mapping
Route::get('packages/{packageId}/levels', [CoursePackageLevelController::class, 'index']);
Route::post('packages/{packageId}/levels', [CoursePackageLevelController::class, 'store']);
Route::delete('packages/{packageId}/levels/{levelId}', [CoursePackageLevelController::class, 'destroy']);

// Assessment submission
Route::post('assessments/{assessmentId}/submit', [AssessmentController::class, 'submitAttempt']);

// Learning progress (strict mode)
Route::get('users/{userId}/courses/{courseId}/progress', [LearningProgressController::class, 'getUserProgress']);
Route::get('users/{userId}/levels/{levelId}/access', [LearningProgressController::class, 'getLevelAccess']);
Route::get('users/{userId}/levels/{levelId}/chapters/progress', [LearningProgressController::class, 'getChapterProgress']);

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');
