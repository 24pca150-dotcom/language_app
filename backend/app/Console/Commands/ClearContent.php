<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;

/**
 * Wipes all learning content (courses, levels, chapters, contents, assessments,
 * live classes, announcements, activities, progress) and uploaded content files.
 *
 * Keeps: users (super admin / staff / students), tenants, properties,
 * packages, property packages, learning modes, access tokens, tenant logos.
 */
class ClearContent extends Command
{
    protected $signature = 'content:clear {--force : Skip the confirmation prompt}';

    protected $description = 'Delete all learning content and uploaded content files, keeping users and tenants';

    private const TABLES = [
        'user_assessment_attempts',
        'user_course_progress',
        'question_options',
        'assessment_questions',
        'assessments',
        'live_class_attachments',
        'live_classes',
        'content_attachments',
        'content_chapters',
        'contents',
        'level_chapter',
        'chapters',
        'course_package_levels',
        'levels',
        'activities',
        'announcements',
        'courses',
    ];

    private const STORAGE_DIRS = ['contents', 'live_classes', 'live-classes', 'attachments'];

    public function handle(): int
    {
        if (!$this->option('force') && !$this->confirm('This permanently deletes ALL content. Users and tenants are kept. Continue?')) {
            $this->info('Cancelled.');
            return self::SUCCESS;
        }

        Schema::disableForeignKeyConstraints();
        try {
            foreach (self::TABLES as $table) {
                if (Schema::hasTable($table)) {
                    $count = DB::table($table)->count();
                    DB::table($table)->truncate();
                    $this->line("Cleared {$table} ({$count} rows)");
                }
            }
        } finally {
            Schema::enableForeignKeyConstraints();
        }

        $disk = Storage::disk('public');
        foreach (self::STORAGE_DIRS as $dir) {
            if ($disk->exists($dir)) {
                $disk->deleteDirectory($dir);
                $this->line("Deleted storage/app/public/{$dir}");
            }
        }

        $this->info('All content removed. Users, tenants, properties and packages are untouched.');
        return self::SUCCESS;
    }
}
