<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Course;
use App\Models\Level;
use App\Models\Chapter;
use App\Models\Content;
use Illuminate\Support\Facades\DB;

class ReadingSkillSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $course = Course::where('name', 'English Course')->first();
        if (!$course) {
            $this->command->error('English Course not found. Please run EnglishCourseSeeder first.');
            return;
        }

        // Create Level
        $level = Level::firstOrCreate(
            ['code' => 'LVL-READING'],
            [
                'name' => 'Reading Skill',
                'description' => 'Develop reading abilities by recognizing letters, words, and sentences.',
                'sort_order' => 2,
                'is_active' => true,
            ]
        );

        // Link Level -> Course Package
        $packageId = DB::table('packages')->where('name', 'Default Package')->value('id');
        if (!$packageId) {
            $packageId = DB::table('packages')->first()->id;
        }
        if ($packageId) {
            DB::table('course_package_levels')->updateOrInsert(
                [
                    'package_id' => $packageId,
                    'course_id' => $course->id,
                    'level_id' => $level->id,
                ],
                [
                    'is_mandatory' => true,
                    'is_active' => true,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]
            );
        }

        // Chapters
        $chapter1 = Chapter::firstOrCreate(
            ['code' => 'CHP-ALPHABET'],
            [
                'name' => 'Alphabet and Letters',
                'description' => 'Learn the English alphabet, vowels, and consonants.',
                'sort_order' => 1,
                'is_active' => true,
            ]
        );

        $chapter2 = Chapter::firstOrCreate(
            ['code' => 'CHP-COMPOUND'],
            [
                'name' => 'Compound Words',
                'description' => 'Explore compound words and how to form them.',
                'sort_order' => 2,
                'is_active' => true,
            ]
        );

        // Link Chapters -> Level
        DB::table('level_chapter')->updateOrInsert(['level_id' => $level->id, 'chapter_id' => $chapter1->id], ['sort_order' => 1, 'is_active' => true]);
        DB::table('level_chapter')->updateOrInsert(['level_id' => $level->id, 'chapter_id' => $chapter2->id], ['sort_order' => 2, 'is_active' => true]);

        // Summarized Content 1: Alphabet and Letters
        $blocks1 = [
            [ "type" => "header", "data" => [ "text" => "Welcome to Reading Skills!" ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Reading helps us understand words, phrases, and stories. The first step to reading is learning the alphabet." ] ],
            [ "type" => "paragraph", "data" => [ "text" => "The English alphabet has 26 letters: A to Z! They are divided into two groups: Vowels and Consonants." ] ],
            
            [ "type" => "header", "data" => [ "text" => "What are Vowels?" ] ],
            [ "type" => "paragraph", "data" => [ "text" => "There are 5 special letters called vowels: <strong>A, E, I, O, U</strong>." ] ],
            [ "type" => "paragraph", "data" => [ "text" => "They are the most important sounds! For example, in the word <strong>Apple</strong>, the vowels are 'a' and 'e'." ] ],
            
            [ "type" => "header", "data" => [ "text" => "What are Consonants?" ] ],
            [ "type" => "paragraph", "data" => [ "text" => "The other 21 letters (like B, C, D, S, T) are called Consonants." ] ],
            [ "type" => "paragraph", "data" => [ "text" => "For example, in the word <strong>Cat</strong>, the consonants are 'c' and 't'." ] ],

            [ "type" => "activity", "data" => [
                "type" => "mcq",
                "question" => "How many vowels are there in the English alphabet?",
                "options" => [
                    [ "id" => 1, "text" => "5", "is_correct" => true ],
                    [ "id" => 2, "text" => "21", "is_correct" => false ]
                ]
            ] ],
            [ "type" => "activity", "data" => [
                "type" => "mcq",
                "question" => "Which are the vowels in the word 'FISH'?",
                "options" => [
                    [ "id" => 1, "text" => "F and S", "is_correct" => false ],
                    [ "id" => 2, "text" => "I", "is_correct" => true ]
                ]
            ] ]
        ];

        // Summarized Content 2: Compound Words
        $blocks2 = [
            [ "type" => "header", "data" => [ "text" => "What are Compound Words?" ] ],
            [ "type" => "paragraph", "data" => [ "text" => "A compound word is formed when two smaller words are combined to make a new word!" ] ],
            [ "type" => "paragraph", "data" => [ "text" => "For example, <strong>Sun</strong> + <strong>Flower</strong> = <strong>Sunflower</strong>." ] ],
            
            [ "type" => "header", "data" => [ "text" => "Types of Compound Words" ] ],
            [ "type" => "paragraph", "data" => [ "text" => "1. <strong>Closed:</strong> No space between words (e.g., notebook, toothbrush)." ] ],
            [ "type" => "paragraph", "data" => [ "text" => "2. <strong>Open:</strong> Written with a space (e.g., ice cream, bus stop)." ] ],
            
            [ "type" => "header", "data" => [ "text" => "Hyphenated Words" ] ],
            [ "type" => "paragraph", "data" => [ "text" => "3. <strong>Hyphenated:</strong> Joined with a hyphen (e.g., part-time, well-known)." ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Ready to test your knowledge? Let's play a matching game!" ] ],

            [ "type" => "activity", "data" => [
                "type" => "mcq",
                "question" => "Which of the following is a Closed Compound Word?",
                "options" => [
                    [ "id" => 1, "text" => "Ice cream", "is_correct" => false ],
                    [ "id" => 2, "text" => "Football", "is_correct" => true ]
                ]
            ] ],
            [ "type" => "activity", "data" => [
                "type" => "mcq",
                "question" => "Sun + Flower = ?",
                "options" => [
                    [ "id" => 1, "text" => "Sunflower", "is_correct" => true ],
                    [ "id" => 2, "text" => "Sunlight", "is_correct" => false ]
                ]
            ] ]
        ];

        $content1Data = [
            'time' => time(),
            'blocks' => $blocks1,
            'version' => '2.29.1'
        ];

        $content2Data = [
            'time' => time(),
            'blocks' => $blocks2,
            'version' => '2.29.1'
        ];

            $content1 = Content::updateOrCreate(
                ['name' => 'Alphabet and Letters Lesson'],
                [
                    'title' => 'Alphabet and Letters',
                    'sort_order' => 1,
                    'is_active' => true,
                    'text_content' => json_encode($content1Data, JSON_UNESCAPED_UNICODE)
                ]
            );

            $content2 = Content::updateOrCreate(
                ['name' => 'Compound Words Lesson'],
                [
                    'title' => 'Compound Words',
                    'sort_order' => 1,
                    'is_active' => true,
                    'text_content' => json_encode($content2Data, JSON_UNESCAPED_UNICODE)
                ]
            );

            // Link Content -> Chapter
            DB::table('content_chapters')->updateOrInsert(['content_id' => $content1->id, 'chapter_id' => $chapter1->id], ['sort_order' => 1]);
            DB::table('content_chapters')->updateOrInsert(['content_id' => $content2->id, 'chapter_id' => $chapter2->id], ['sort_order' => 1]);


        // Delete original Content
        Content::where('name', 'Reading Skill')->delete();
    }
}
