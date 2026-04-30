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
        Schema::table('contents', function (Blueprint $table) {
            $table->text('image')->nullable()->change();
            $table->text('video')->nullable()->change();
            $table->text('pdf')->nullable()->change();
            $table->text('doc')->nullable()->change();
            $table->text('xlsx')->nullable()->change();
            $table->text('ppt')->nullable()->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('contents', function (Blueprint $table) {
            $table->string('image')->nullable()->change();
            $table->string('video')->nullable()->change();
            $table->string('pdf')->nullable()->change();
            $table->string('doc')->nullable()->change();
            $table->string('xlsx')->nullable()->change();
            $table->string('ppt')->nullable()->change();
        });
    }
};
