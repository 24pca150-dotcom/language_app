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
            $columns = ['image', 'video', 'pdf', 'doc', 'xlsx', 'ppt'];
            foreach ($columns as $column) {
                if (Schema::hasColumn('contents', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('contents', function (Blueprint $table) {
            $table->json('image')->nullable();
            $table->json('video')->nullable();
            $table->json('pdf')->nullable();
            $table->json('doc')->nullable();
            $table->json('xlsx')->nullable();
            $table->json('ppt')->nullable();
        });
    }
};