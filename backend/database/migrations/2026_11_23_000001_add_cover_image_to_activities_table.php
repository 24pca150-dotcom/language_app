<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Picture shown behind the activity's game card in the mobile app.
     */
    public function up(): void
    {
        Schema::table('activities', function (Blueprint $table) {
            $table->string('cover_image', 1000)->nullable()->after('type');
        });
    }

    public function down(): void
    {
        Schema::table('activities', function (Blueprint $table) {
            $table->dropColumn('cover_image');
        });
    }
};
