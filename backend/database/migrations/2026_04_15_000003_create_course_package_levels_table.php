<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('course_package_levels', function (Blueprint $table) {
            $table->id();
            $table->foreignId('package_id')->constrained('packages')->onDelete('cascade');
            $table->foreignId('level_id')->constrained('levels')->onDelete('cascade');
            $table->boolean('is_active')->default(1);
            $table->unique(['package_id', 'level_id'], 'unique_package_level');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('course_package_levels');
    }
};
