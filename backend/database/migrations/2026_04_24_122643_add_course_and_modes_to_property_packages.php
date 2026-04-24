<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('property_packages', function (Blueprint $table) {
            $table->foreignId('course_id')->nullable()->after('package_id')->constrained('courses')->onDelete('set null');
            $table->text('learning_mode_ids')->nullable()->after('course_id'); // Store as JSON array
            
            // Remove unique constraint if it exists to allow same package for different courses if needed
            // But usually property-package is unique. For now, we leave it.
        });
    }

    public function down(): void
    {
        Schema::table('property_packages', function (Blueprint $table) {
            $table->dropForeign(['course_id']);
            $table->dropColumn(['course_id', 'learning_mode_ids']);
        });
    }
};
