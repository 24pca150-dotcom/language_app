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
        Schema::table('assessments', function (Blueprint $table) {
            if (!Schema::hasColumn('assessments', 'scheduled_date')) {
                $table->dateTime('scheduled_date')->nullable()->after('duration_minutes');
            }
            if (!Schema::hasColumn('assessments', 'open_hours')) {
                $table->decimal('open_hours', 6, 2)->nullable()->after('scheduled_date');
            }
            if (!Schema::hasColumn('assessments', 'due_date')) {
                $table->dateTime('due_date')->nullable()->after('open_hours');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('assessments', function (Blueprint $table) {
            if (Schema::hasColumn('assessments', 'due_date')) {
                $table->dropColumn('due_date');
            }
            if (Schema::hasColumn('assessments', 'open_hours')) {
                $table->dropColumn('open_hours');
            }
            if (Schema::hasColumn('assessments', 'scheduled_date')) {
                $table->dropColumn('scheduled_date');
            }
        });
    }
};
