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
        Schema::create('contents', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->integer('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->text('text_content')->nullable();
            $table->string('external_url')->nullable();
            $table->string('image')->nullable();
            $table->string('video')->nullable();
            $table->string('pdf')->nullable();
            $table->string('doc')->nullable();
            $table->string('xlsx')->nullable();
            $table->string('ppt')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('contents');
    }
};
