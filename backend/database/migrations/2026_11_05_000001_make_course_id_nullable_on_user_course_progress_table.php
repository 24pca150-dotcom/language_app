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
        // Game and practice rows are not tied to a course
        Schema::table('user_course_progress', function (Blueprint $table) {
            $table->unsignedBigInteger('course_id')->nullable()->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('user_course_progress', function (Blueprint $table) {
            $table->unsignedBigInteger('course_id')->nullable(false)->change();
        });
    }
};
