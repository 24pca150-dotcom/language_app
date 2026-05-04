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
        Schema::create('content_attachments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('content_id')->nullable()->constrained()->onDelete('cascade');
            $table->string('unique_id')->unique();
            $table->string('original_name');
            $table->string('alias_name')->nullable();
            $table->string('file_size');
            $table->string('file_extension');
            $table->string('uploaded_by')->nullable();
            $table->boolean('is_deleted')->default(false);
            $table->string('deleted_by')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('content_attachments');
    }
};
