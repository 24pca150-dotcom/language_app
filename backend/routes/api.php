<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\PackageController;
use App\Http\Controllers\TenantController;
use App\Http\Controllers\PropertyController;
use App\Http\Controllers\CourseController;
use App\Http\Controllers\LevelController;
use App\Http\Controllers\ChapterController;
use App\Http\Controllers\AssessmentController;
use App\Http\Controllers\LearningProgressController;
use App\Http\Controllers\LearningModeController;
use App\Http\Controllers\ContentController;

// Existing resources
Route::apiResource('packages', PackageController::class);
Route::apiResource('tenants', TenantController::class);
Route::apiResource('properties', PropertyController::class);

// New resources
Route::apiResource('courses', CourseController::class);
Route::get('courses/{course}/player-structure', [CourseController::class, 'getPlayerStructure']);
Route::apiResource('levels', LevelController::class);
Route::apiResource('chapters', ChapterController::class);
Route::post('contents/upload', [ContentController::class, 'upload']);
Route::apiResource('contents', ContentController::class);
Route::apiResource('assessments', AssessmentController::class);
Route::apiResource('learning-modes', LearningModeController::class);

// Course-Package-Level mapping (Consolidated in PackageController)
Route::get('packages/{packageId}/levels', [PackageController::class, 'getLevels']);
Route::post('packages/{packageId}/levels', [PackageController::class, 'mapLevels']);
Route::delete('packages/{packageId}/levels/{levelId}', [PackageController::class, 'unmapLevel']);

// Assessment submission
Route::post('assessments/{assessmentId}/submit', [AssessmentController::class, 'submitAttempt']);

// Learning progress (strict mode)
Route::get('users/{userId}/courses/{courseId}/progress', [LearningProgressController::class, 'getUserProgress']);
Route::get('users/{userId}/levels/{levelId}/access', [LearningProgressController::class, 'getLevelAccess']);
Route::get('users/{userId}/levels/{levelId}/chapters/progress', [LearningProgressController::class, 'getChapterProgress']);

// Level-Chapter mapping (Consolidated in LevelController)
Route::get('levels/{levelId}/chapters', [LevelController::class, 'getChapters']);
Route::post('levels/{levelId}/chapters', [LevelController::class, 'mapChapters']);
Route::delete('levels/{levelId}/chapters/{chapterId}', [LevelController::class, 'unmapChapter']);
Route::post('levels/{levelId}/chapters/reorder', [LevelController::class, 'reorderChapters']);

// Chapter-Level mapping (Consolidated in ChapterController)
Route::get('chapters/{chapterId}/levels', [ChapterController::class, 'getLevels']);
Route::post('chapters/{chapterId}/levels', [ChapterController::class, 'mapLevels']);

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');
