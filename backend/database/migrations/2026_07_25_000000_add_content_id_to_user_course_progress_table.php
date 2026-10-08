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
        Schema::table('user_course_progress', function (Blueprint $table) {
            if (!Schema::hasColumn('user_course_progress', 'content_id')) {
                $table->foreignId('content_id')->nullable()->after('chapter_id')->constrained('contents')->onDelete('cascade');
                $table->index(['user_id', 'content_id']);
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('user_course_progress', function (Blueprint $table) {
            if (Schema::hasColumn('user_course_progress', 'content_id')) {
                $table->dropForeign(['content_id']);
                $table->dropIndex(['user_id', 'content_id']);
                $table->dropColumn('content_id');
            }
        });
    }
};
