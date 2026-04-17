<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Levels table: Adding Objectives
        Schema::table('levels', function (Blueprint $table) {
            $table->text('objective_listening')->nullable();
            $table->text('objective_speaking')->nullable();
            $table->text('objective_reading')->nullable();
            $table->text('objective_writing')->nullable();
        });

        // 2 & 3. SubChapters: adjusting content metadata
        Schema::table('sub_chapters', function (Blueprint $table) {
            $table->json('content_meta')->nullable()->comment('Handles images array, slide carousels, downloadable URLs');
        });

        // Chapters: Allow them to also hold content directly
        Schema::table('chapters', function (Blueprint $table) {
            $table->string('content_type', 50)->default('text')->comment('text, video, file, image, slide_view, mixed');
            $table->text('content')->nullable();
            $table->json('content_meta')->nullable();
        });

        // 4, 5, 6. Assessments Table:
        Schema::table('assessments', function (Blueprint $table) {
            $table->dropForeign(['level_id']);
        });
        Schema::table('assessments', function (Blueprint $table) {
            $table->unsignedBigInteger('level_id')->nullable()->change();
            $table->foreign('level_id')->references('id')->on('levels')->onDelete('cascade');
            
            $table->foreignId('chapter_id')->nullable()->constrained('chapters')->onDelete('cascade');
            $table->foreignId('sub_chapter_id')->nullable()->constrained('sub_chapters')->onDelete('cascade');
            
            $table->boolean('is_mandatory')->default(true);
            $table->integer('duration_minutes')->nullable();
            $table->boolean('allow_restart')->default(true);
            $table->string('review_mode', 50)->default('after_completion')->comment('instantly, after_completion');
            $table->string('activity_type', 50)->default('plain')->comment('listen_audio, read_passage, watch_video, plain');
            $table->longText('prelude_content')->nullable()->comment('Passage text, or media URLs for activity');
        });

        // Advanced Question Types
        Schema::table('assessment_questions', function (Blueprint $table) {
            $table->string('question_type', 50)->default('multiple_choice');
            $table->json('additional_data')->nullable()->comment('Stores complex configuration');
            $table->string('media_url')->nullable()->comment('Question specific audio/image/video');
        });
    }

    public function down(): void
    {
        Schema::table('assessment_questions', function (Blueprint $table) {
            $table->dropColumn(['question_type', 'additional_data', 'media_url']);
        });

        Schema::table('assessments', function (Blueprint $table) {
            $table->dropForeign(['sub_chapter_id']);
            $table->dropForeign(['chapter_id']);
            $table->dropColumn([
                'chapter_id', 'sub_chapter_id', 'is_mandatory', 'duration_minutes', 
                'allow_restart', 'review_mode', 'activity_type', 'prelude_content'
            ]);
        });

        Schema::table('chapters', function (Blueprint $table) {
            $table->dropColumn(['content_type', 'content', 'content_meta']);
        });

        Schema::table('sub_chapters', function (Blueprint $table) {
            $table->dropColumn('content_meta');
        });

        Schema::table('levels', function (Blueprint $table) {
            $table->dropColumn([
                'objective_listening', 'objective_speaking', 'objective_reading', 'objective_writing'
            ]);
        });
    }
};
