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
        Schema::table('chapters', function (Blueprint $table) {
            $table->dropForeign(['level_id']);
            $table->dropColumn(['level_id', 'content_type', 'content', 'content_meta']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('chapters', function (Blueprint $table) {
            $table->foreignId('level_id')->nullable()->constrained('levels')->cascadeOnDelete();
            $table->string('content_type', 50)->nullable();
            $table->text('content')->nullable();
            $table->json('content_meta')->nullable();
        });
    }
};
