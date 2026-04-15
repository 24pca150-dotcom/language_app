<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('assessments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('level_id')->constrained('levels')->onDelete('cascade');
            $table->string('title', 255);
            $table->text('description')->nullable();
            $table->decimal('pass_percentage', 5, 2)->default(70.00);
            $table->boolean('is_active')->default(1);
            $table->timestamps();
        });

        Schema::create('assessment_questions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('assessment_id')->constrained('assessments')->onDelete('cascade');
            $table->text('question_text');
            $table->integer('sort_order')->default(0);
            $table->timestamps();
        });

        Schema::create('question_options', function (Blueprint $table) {
            $table->id();
            $table->foreignId('question_id')->constrained('assessment_questions')->onDelete('cascade');
            $table->string('option_text', 500);
            $table->boolean('is_correct')->default(false);
            $table->integer('sort_order')->default(0);
            $table->timestamps();
        });

        Schema::create('user_assessment_attempts', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->foreignId('assessment_id')->constrained('assessments')->onDelete('cascade');
            $table->decimal('score', 5, 2)->default(0);
            $table->boolean('passed')->default(false);
            $table->timestamp('attempted_at')->useCurrent();
            $table->timestamps();

            $table->index(['user_id', 'assessment_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_assessment_attempts');
        Schema::dropIfExists('question_options');
        Schema::dropIfExists('assessment_questions');
        Schema::dropIfExists('assessments');
    }
};
