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
        Schema::table('property_packages', function (Blueprint $table) {
            if (Schema::hasColumn('property_packages', 'allowed_learning_modes')) {
                $table->renameColumn('allowed_learning_modes', 'learning_mode_ids');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('property_packages', function (Blueprint $table) {
            if (Schema::hasColumn('property_packages', 'learning_mode_ids')) {
                $table->renameColumn('learning_mode_ids', 'allowed_learning_modes');
            }
        });
    }
};
