<?php
require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\Tenant;
use App\Models\User;
use App\Models\Property;
use App\Models\Package;
use App\Models\Course;
use App\Models\Level;
use App\Models\Chapter;
use App\Models\Content;
use Illuminate\Support\Facades\DB;

echo "Starting course creation and mapping for student Arjune.A...\n";

// 1. Locate student user
$student = User::where('name', 'like', '%Arjune%')->where('role', 'student')->first();
if (!$student) {
    echo "ERROR: Student user Arjune.A not found!\n";
    exit(1);
}
echo "Found student: ID {$student->id}, Name: {$student->name}, Tenant ID: {$student->tenant_id}\n";

$tenantId = $student->tenant_id ?: 3;

// 2. Ensure Property exists for this tenant
$property = Property::where('tenant_id', $tenantId)->first();
if (!$property) {
    $property = Property::create([
        'tenant_id' => $tenantId,
        'property_code' => 'PROP-MAC-01',
        'property_name' => 'MACVEL Campus',
        'location' => 'Sivakasi',
        'address' => 'Sivakasi Campus',
        'max_users' => 1000,
        'is_active' => true,
    ]);
    echo "Created Property: ID {$property->id}, Name: {$property->property_name}\n";
} else {
    echo "Existing Property: ID {$property->id}, Name: {$property->property_name}\n";
}

// 3. Create or find Package
$package = Package::firstOrCreate(
    ['code' => 'PKG-ENG-01'],
    [
        'name' => 'English Mastery Package',
        'description' => 'Comprehensive spoken & written English curriculum package.',
        'is_active' => true,
    ]
);
echo "Package: ID {$package->id}, Name: {$package->name}\n";

// 4. Create Course
$course = Course::firstOrCreate(
    ['name' => 'English for Beginners'],
    [
        'code' => 'CRS-ENG-001',
        'description' => 'Master everyday conversational English, greetings, vocabulary, and practical sentences.',
        'no_of_levels' => 1,
        'is_active' => true,
    ]
);
echo "Course: ID {$course->id}, Name: {$course->name}, Code: {$course->code}\n";

// 5. Create Level
$level = Level::firstOrCreate(
    ['name' => 'Level 1 - Starter English'],
    [
        'code' => 'LVL-ENG-01',
        'description' => 'Basic greetings, phonetics, and introductory conversations.',
        'estimated_hours' => 10,
        'sort_order' => 1,
        'is_active' => true,
    ]
);
echo "Level: ID {$level->id}, Name: {$level->name}\n";

// 6. Create Chapter
$chapter = Chapter::firstOrCreate(
    ['name' => 'Chapter 1: Daily Greetings & Introductions'],
    [
        'code' => 'CHP-ENG-01',
        'description' => 'Learn essential everyday greetings and how to introduce yourself fluently.',
        'sort_order' => 1,
        'is_active' => true,
    ]
);
echo "Chapter: ID {$chapter->id}, Name: {$chapter->name}\n";

// 7. Map Level to Chapter
$levelChapterExists = DB::table('level_chapter')
    ->where('level_id', $level->id)
    ->where('chapter_id', $chapter->id)
    ->exists();
if (!$levelChapterExists) {
    DB::table('level_chapter')->insert([
        'level_id' => $level->id,
        'chapter_id' => $chapter->id,
        'sort_order' => 1,
        'is_active' => true,
        'created_at' => now(),
        'updated_at' => now(),
    ]);
    echo "Mapped Level {$level->id} -> Chapter {$chapter->id}\n";
}

// 8. Create Content
$content = Content::firstOrCreate(
    ['name' => 'Lesson 1: Common Greetings'],
    [
        'title' => 'Saying Hello & Everyday Etiquette',
        'text_content' => '<p>Welcome! In this lesson we learn standard everyday conversational English:</p><ul><li>Good morning / Good afternoon</li><li>How are you today?</li><li>Nice to meet you!</li></ul>',
        'sort_order' => 1,
        'is_active' => true,
    ]
);
echo "Content: ID {$content->id}, Name: {$content->name}\n";

// Map Chapter to Content
$chapterContentExists = DB::table('content_chapters')
    ->where('content_id', $content->id)
    ->where('chapter_id', $chapter->id)
    ->exists();
if (!$chapterContentExists) {
    DB::table('content_chapters')->insert([
        'content_id' => $content->id,
        'chapter_id' => $chapter->id,
        'sort_order' => 1,
        'created_at' => now(),
        'updated_at' => now(),
    ]);
    echo "Mapped Chapter {$chapter->id} -> Content {$content->id}\n";
}

// 9. Map Course, Package, Level in course_package_levels
$cplExists = DB::table('course_package_levels')
    ->where('course_id', $course->id)
    ->where('package_id', $package->id)
    ->where('level_id', $level->id)
    ->exists();
if (!$cplExists) {
    DB::table('course_package_levels')->insert([
        'course_id' => $course->id,
        'package_id' => $package->id,
        'level_id' => $level->id,
        'is_mandatory' => true,
        'is_active' => true,
        'created_at' => now(),
        'updated_at' => now(),
    ]);
    echo "Mapped Course {$course->id} + Package {$package->id} + Level {$level->id} in course_package_levels\n";
}

// 10. Map Property + Package + Course in property_packages
$ppExists = DB::table('property_packages')
    ->where('property_id', $property->id)
    ->where('package_id', $package->id)
    ->where('course_id', $course->id)
    ->exists();
if (!$ppExists) {
    DB::table('property_packages')->insert([
        'property_id' => $property->id,
        'package_id' => $package->id,
        'course_id' => $course->id,
        'is_active' => true,
        'start_date' => now()->subDay()->toDateString(),
        'end_date' => now()->addYear()->toDateString(),
        'created_at' => now(),
        'updated_at' => now(),
    ]);
    echo "Mapped Property {$property->id} + Package {$package->id} + Course {$course->id} in property_packages\n";
}

echo "\n--- VERIFYING STUDENT ACCESS ---\n";
$today = now()->toDateString();
$accessibleCourses = Course::where('is_active', true)
    ->whereIn('id', function($query) use ($student, $today) {
        $query->select('property_packages.course_id')
            ->from('property_packages')
            ->join('properties', 'property_packages.property_id', '=', 'properties.id')
            ->where('properties.tenant_id', $student->tenant_id)
            ->where('property_packages.is_active', true)
            ->whereNotNull('property_packages.course_id')
            ->where(function ($q) use ($today) {
                $q->whereNull('property_packages.start_date')
                  ->orWhere('property_packages.start_date', '<=', $today);
            })
            ->where(function ($q) use ($today) {
                $q->whereNull('property_packages.end_date')
                  ->orWhere('property_packages.end_date', '>=', $today);
            });
    })->latest()->get();

echo "Accessible courses for {$student->name}: " . $accessibleCourses->count() . "\n";
foreach ($accessibleCourses as $ac) {
    echo " - [ID: {$ac->id}] {$ac->name} (Code: {$ac->code})\n";
}

echo "SUCCESS!\n";
