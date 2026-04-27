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
        Schema::create('content_chapters', function (Blueprint $table) {
            $table->id();
            $table->foreignId('content_id')->constrained()->onDelete('cascade');
            $table->foreignId('chapter_id')->constrained()->onDelete('cascade');
            $table->timestamps();
            
            $table->unique(['content_id', 'chapter_id']);
        });
        
        // Also remove the old single chapter_id column if it exists
        if (Schema::hasColumn('contents', 'chapter_id')) {
            Schema::table('contents', function (Blueprint $table) {
                $table->dropForeign(['chapter_id']);
                $table->dropColumn('chapter_id');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('content_chapters');
        
        Schema::table('contents', function (Blueprint $table) {
            $table->foreignId('chapter_id')->nullable()->constrained()->onDelete('set null');
        });
    }
};
