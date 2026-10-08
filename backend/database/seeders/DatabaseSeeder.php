<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Tenant;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Clean up remaining course/curriculum data from database
        Schema::disableForeignKeyConstraints();
        
        $tables = [
            'course_package_levels',
            'level_chapter',
            'content_chapters',
            'property_packages',
            'content_attachments',
            'question_options',
            'assessment_questions',
            'user_assessment_attempts',
            'assessments',
            'user_course_progress',
            'contents',
            'chapters',
            'levels',
            'courses',
            'activities',
            'properties',
        ];

        foreach ($tables as $table) {
            if (Schema::hasTable($table)) {
                if (DB::getDriverName() === 'pgsql') {
                    DB::statement("TRUNCATE TABLE {$table} CASCADE;");
                } else {
                    DB::table($table)->truncate();
                }
            }
        }

        if (Schema::hasTable('tenants')) {
            DB::table('tenants')->where('tenant_code', '!=', 'SCH-001')->delete();
        }
        if (Schema::hasTable('users')) {
            DB::table('users')->whereNotIn('username', ['superadmin', 'coordinator', 'karthik_std'])->delete();
        }
        
        Schema::enableForeignKeyConstraints();

        // 1. Seed Super Admin (Global Administrator with no tenant_id)
        User::updateOrCreate(
            ['email' => 'admin@ariga.local'],
            [
                'username' => 'superadmin',
                'name' => 'Super Admin',
                'password' => Hash::make('admin123'),
                'role' => 'super_admin',
                'tenant_id' => null,
            ]
        );

        // 2. Seed a default Tenant (strictly required to link tenant-scoped users)
        $tenant = Tenant::updateOrCreate(
            ['tenant_code' => 'SCH-001'],
            [
                'tenant_name' => 'Ariga Public School',
                'contact_person' => 'Principal Office',
                'email' => 'contact@ariga.school',
                'is_active' => true,
                'primary_color' => '#7c3aed',
                'secondary_color' => '#db2777',
            ]
        );

        // 4. Seed Staff (School Coordinator)
        User::updateOrCreate(
            ['email' => 'manager@ariga.school'],
            [
                'username' => 'staff',
                'name' => 'Staff',
                'password' => Hash::make('test123'),
                'role' => 'staff',
                'tenant_id' => $tenant->id,
            ]
        );

        // 5. Seed Student
        User::updateOrCreate(
            ['username' => 'karthik'],
            [
                'name' => 'Karthik',
                'email' => null,
                'password' => Hash::make('student123'),
                'role' => 'student',
                'tenant_id' => $tenant->id,
            ]
        );

        $this->call(EnglishCourseSeeder::class);
        $this->call(WritingSkillSeeder::class);
        $this->call(ListeningSkillSeeder::class);
        $this->call(ReadingSkillSeeder::class);
        $this->call(SpeakingSkillSeeder::class);
        $this->call(InteractiveFeaturesTestSeeder::class);
        $this->call(ActivitySeeder::class);
    }
}

