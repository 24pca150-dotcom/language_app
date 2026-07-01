<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Course;
use App\Models\Level;
use App\Models\Chapter;
use App\Models\Content;
use Illuminate\Support\Facades\DB;

class SpeakingSkillSeeder extends Seeder
{
    public function run(): void
    {
        $course = Course::where('name', 'English Course')->first();
        if (!$course) return;

        // Level
        $level = Level::firstOrCreate(
            ['code' => 'LVL-SPEAKING'],
            [
                'name' => 'Speaking Skill',
                'description' => 'Develop speaking abilities and learn the parts of speech.',
                'sort_order' => 3,
                'is_active' => true,
            ]
        );

        $packageId = DB::table('packages')->where('name', 'Default Package')->value('id');
        if (!$packageId) $packageId = DB::table('packages')->first()->id;

        if ($packageId) {
            DB::table('course_package_levels')->updateOrInsert(
                ['package_id' => $packageId, 'course_id' => $course->id, 'level_id' => $level->id],
                ['is_mandatory' => true, 'is_active' => true, 'created_at' => now(), 'updated_at' => now()]
            );
        }

        // Chapters
        $chapter1 = Chapter::firstOrCreate(['code' => 'CHP-PARTSOFSPEECH'], ['name' => 'Parts of Speech', 'description' => 'Learn the 8 parts of speech.', 'sort_order' => 1, 'is_active' => true]);
        $chapter2 = Chapter::firstOrCreate(['code' => 'CHP-SENTENCES'], ['name' => 'Sentence Building & Expressions', 'description' => 'Arrange sentences and express emotions.', 'sort_order' => 2, 'is_active' => true]);

        DB::table('level_chapter')->updateOrInsert(['level_id' => $level->id, 'chapter_id' => $chapter1->id], ['sort_order' => 1, 'is_active' => true]);
        DB::table('level_chapter')->updateOrInsert(['level_id' => $level->id, 'chapter_id' => $chapter2->id], ['sort_order' => 2, 'is_active' => true]);

        $blocks1 = [
            [ "type" => "header", "data" => [ "text" => "Welcome to Speaking Skills!" ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Speaking helps us express our thoughts clearly and confidently! Words are like building blocks of sentences. There are 8 parts of speech!" ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Let's explore them in this lesson." ] ],
            
            [ "type" => "header", "data" => [ "text" => "Nouns, Pronouns, Verbs & Adjectives" ] ],
            [ "type" => "paragraph", "data" => [ "text" => "<strong>Noun:</strong> Naming word (e.g. Teacher, Chennai, Book).<br><strong>Pronoun:</strong> Replaces a noun (e.g. He, She, They)." ] ],
            [ "type" => "paragraph", "data" => [ "text" => "<strong>Verb:</strong> Action word (e.g. Run, Sing, Jump).<br><strong>Adjective:</strong> Describing word (e.g. Beautiful, Tall, Red)." ] ],
            
            [ "type" => "header", "data" => [ "text" => "Adverbs, Prepositions, Conjunctions & Interjections" ] ],
            [ "type" => "paragraph", "data" => [ "text" => "<strong>Adverb:</strong> Describes a verb (e.g. Quickly, Happily).<br><strong>Preposition:</strong> Shows position (e.g. In, On, Under)." ] ],
            [ "type" => "paragraph", "data" => [ "text" => "<strong>Conjunction:</strong> Joining word (e.g. And, But).<br><strong>Interjection:</strong> Sudden emotion (e.g. Wow!, Ouch!)." ] ],

            [ "type" => "activity", "data" => [ "type" => "mcq", "question" => "Identify the Adjective: The happy child played in the park.", "options" => [ [ "id" => 1, "text" => "happy", "is_correct" => true ], [ "id" => 2, "text" => "child", "is_correct" => false ] ] ] ],
            [ "type" => "activity", "data" => [ "type" => "mcq", "question" => "Identify the Pronoun: She is my best friend.", "options" => [ [ "id" => 1, "text" => "best", "is_correct" => false ], [ "id" => 2, "text" => "She", "is_correct" => true ] ] ] ]
        ];

        $blocks2 = [
            [ "type" => "header", "data" => [ "text" => "Word Arrangement" ] ],
            [ "type" => "paragraph", "data" => [ "text" => "The order of words is important! Arranging words correctly helps you speak clearly." ] ],
            [ "type" => "paragraph", "data" => [ "text" => "For example: <strong>eating / an / apple / I / am</strong> should be <strong>I am eating an apple.</strong>" ] ],
            
            [ "type" => "header", "data" => [ "text" => "Expressing Emotions" ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Interjections help us show sudden feelings like joy, surprise, or sadness." ] ],
            [ "type" => "paragraph", "data" => [ "text" => "<strong>Wow!</strong> (Surprise), <strong>Hurray!</strong> (Joy), <strong>Alas!</strong> (Sadness), <strong>Ouch!</strong> (Pain)." ] ],
            
            [ "type" => "header", "data" => [ "text" => "More Expressions" ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Here are some more interjections you can use in daily speaking:" ] ],
            [ "type" => "paragraph", "data" => [ "text" => "<strong>Oops!</strong> (Mistake), <strong>Bravo!</strong> (Praise), <strong>Yuck!</strong> (Disgust), <strong>Shh!</strong> (Silence)." ] ],

            [ "type" => "activity", "data" => [ "type" => "word_arrange", "question" => "Arrange the words to form a correct sentence:", "text" => "They are playing football" ] ],
            [ "type" => "activity", "data" => [ "type" => "word_arrange", "question" => "Arrange the words to form a correct sentence:", "text" => "Mother is baking a cake" ] ],
            [ "type" => "activity", "data" => [ "type" => "mcq", "question" => "Which interjection shows Sudden Pain?", "options" => [ [ "id" => 1, "text" => "Ouch!", "is_correct" => true ], [ "id" => 2, "text" => "Hurray!", "is_correct" => false ] ] ] ]
        ];

        $content1 = Content::updateOrCreate(['name' => 'Parts of Speech Lesson'], ['title' => 'Parts of Speech', 'sort_order' => 1, 'is_active' => true, 'text_content' => json_encode(['time' => time(), 'blocks' => $blocks1, 'version' => '2.29.1'], JSON_UNESCAPED_UNICODE)]);
        $content2 = Content::updateOrCreate(['name' => 'Sentences Lesson'], ['title' => 'Sentence Building & Expressions', 'sort_order' => 1, 'is_active' => true, 'text_content' => json_encode(['time' => time(), 'blocks' => $blocks2, 'version' => '2.29.1'], JSON_UNESCAPED_UNICODE)]);

        DB::table('content_chapters')->updateOrInsert(['content_id' => $content1->id, 'chapter_id' => $chapter1->id], ['sort_order' => 1]);
        DB::table('content_chapters')->updateOrInsert(['content_id' => $content2->id, 'chapter_id' => $chapter2->id], ['sort_order' => 1]);
    }
}
