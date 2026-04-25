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
            $table->dropForeign(['sub_chapter_id']);
            $table->dropColumn('sub_chapter_id');
        });

        Schema::table('user_course_progress', function (Blueprint $table) {
            $table->dropForeign(['sub_chapter_id']);
            $table->dropColumn('sub_chapter_id');
        });

        Schema::dropIfExists('sub_chapters');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Not needed for removing.
    }
};
