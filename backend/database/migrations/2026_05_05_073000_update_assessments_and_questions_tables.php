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
        Schema::table('assessments', function (Blueprint $table) {
            // Add missing columns
            if (!Schema::hasColumn('assessments', 'chapter_id')) {
                $table->foreignId('chapter_id')->nullable()->after('level_id')->constrained('chapters')->onDelete('cascade');
            }
            
            if (!Schema::hasColumn('assessments', 'duration_minutes')) {
                if (Schema::hasColumn('assessments', 'time_limit_minutes')) {
                    $table->renameColumn('time_limit_minutes', 'duration_minutes');
                } else {
                    $table->integer('duration_minutes')->nullable()->after('passing_marks');
                }
            }

            if (!Schema::hasColumn('assessments', 'allow_restart')) {
                $table->boolean('allow_restart')->default(false)->after('duration_minutes');
            }

            if (!Schema::hasColumn('assessments', 'review_mode')) {
                $table->string('review_mode')->nullable()->after('allow_restart');
            }

            if (!Schema::hasColumn('assessments', 'activity_type')) {
                $table->string('activity_type')->nullable()->after('review_mode');
            }

            if (!Schema::hasColumn('assessments', 'prelude_content')) {
                $table->text('prelude_content')->nullable()->after('activity_type');
            }

            // Make level_id nullable if it exists
            $table->foreignId('level_id')->nullable()->change();
        });

        Schema::table('assessment_questions', function (Blueprint $table) {
            if (!Schema::hasColumn('assessment_questions', 'question_type')) {
                $table->string('question_type')->default('multiple_choice')->after('question_text');
            }
            if (!Schema::hasColumn('assessment_questions', 'additional_data')) {
                $table->json('additional_data')->nullable()->after('question_type');
            }
            if (!Schema::hasColumn('assessment_questions', 'media_url')) {
                $table->string('media_url')->nullable()->after('additional_data');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('assessments', function (Blueprint $table) {
            $table->dropForeign(['chapter_id']);
            $table->dropColumn(['chapter_id', 'allow_restart', 'review_mode', 'activity_type', 'prelude_content']);
            $table->renameColumn('duration_minutes', 'time_limit_minutes');
            $table->foreignId('level_id')->nullable(false)->change();
        });

        Schema::table('assessment_questions', function (Blueprint $table) {
            $table->dropColumn(['question_type', 'additional_data', 'media_url']);
        });
    }
};
