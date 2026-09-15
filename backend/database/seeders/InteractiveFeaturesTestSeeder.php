<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Tenant;
use App\Models\Property;
use App\Models\Package;
use App\Models\Course;
use App\Models\Level;
use App\Models\Chapter;
use App\Models\Content;
use App\Models\Activity;
use Illuminate\Support\Facades\DB;

class InteractiveFeaturesTestSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 1. Get Course and Package
        $package = Package::firstOrCreate(
            ['code' => 'PKG-ENGLISH-BEGINNER'],
            [
                'name' => 'English for Beginner Package',
                'description' => 'Complete package containing all English skill levels.',
                'is_active' => true
            ]
        );

        $course = Course::firstOrCreate(
            ['name' => 'English for Beginner'],
            [
                'description' => 'Learn English step by step with writing, listening, reading, and speaking skills.',
                'is_active' => true
            ]
        );

        // 2. Create Level "Test"
        $level = Level::updateOrCreate(
            ['code' => 'LVL-INTERACTIVE-TEST'],
            [
                'name' => 'Interactive Demo Test',
                'description' => 'Test level showcasing new interactive features (MCQ, Matching & Writing).',
                'sort_order' => 6,
                'is_active' => true,
            ]
        );

        // Map Level -> Course & Package
        DB::table('course_package_levels')->updateOrInsert(
            [
                'course_id' => $course->id,
                'package_id' => $package->id,
                'level_id' => $level->id,
            ],
            [
                'is_mandatory' => true,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]
        );

        // 3. Create Chapter "Interactive Features"
        $chapter = Chapter::updateOrCreate(
            ['code' => 'CHP-INTERACTIVE-DEMO'],
            [
                'name' => 'Interactive Features Demo',
                'description' => 'Try all our newly added interactive features including double-sided cloud matches, MCQ audio triggers, and image-based writing.',
                'sort_order' => 1,
                'is_active' => true,
            ]
        );

        // Link Level -> Chapter
        DB::table('level_chapter')->updateOrInsert(
            ['level_id' => $level->id, 'chapter_id' => $chapter->id],
            ['sort_order' => 1, 'is_active' => true, 'created_at' => now(), 'updated_at' => now()]
        );

        // Delete previous custom activities to avoid duplicates
        Activity::whereNull('tenant_id')->where(function ($q) {
            $q->where('title', 'like', 'Demo MCQ - %')
              ->orWhere('title', 'like', 'Demo Match - %')
              ->orWhere('title', 'like', 'Demo Writing - %');
        })->delete();

        // 4. Create the Activities
        // MCQ with images and audio play buttons
        $mcqAct = Activity::create([
            'title' => 'Demo MCQ - Animal Sounds',
            'type' => 'mcq',
            'data_json' => [
                'question' => 'Listen carefully to the sounds of these animals. Which sound is made by a <strong>Dog</strong>?',
                'imageUrl' => 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=400&q=80',
                'options' => [
                    [
                        'id' => 1,
                        'text' => 'Dog (Woof!)',
                        'is_correct' => true,
                        'imageUrl' => 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=150&q=80',
                        'audioUrl' => 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'
                    ],
                    [
                        'id' => 2,
                        'text' => 'Cat (Meow!)',
                        'is_correct' => false,
                        'imageUrl' => 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=150&q=80',
                        'audioUrl' => 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3'
                    ],
                    [
                        'id' => 3,
                        'text' => 'Lion (Roar!)',
                        'is_correct' => false,
                        'imageUrl' => 'https://images.unsplash.com/photo-1546182990-dffeafbe841d?auto=format&fit=crop&w=150&q=80',
                        'audioUrl' => 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3'
                    ]
                ]
            ],
            'created_by' => null
        ]);

        // Cloud match with double-sided images, audios, and compound result cards
        $matchAct = Activity::create([
            'title' => 'Demo Match - Cloud Compound Words',
            'type' => 'match',
            'data_json' => [
                'question' => 'Match the words on the left and right clouds to build compound words with their combined picture and text!',
                'theme' => 'cloud',
                'enableAudio' => true,
                'pairs' => [
                    [
                        'left' => 'Sun',
                        'leftImage' => 'https://images.unsplash.com/photo-1534796636912-3b95b3ab5986?auto=format&fit=crop&w=150&q=80',
                        'leftAudio' => 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
                        'right' => 'Flower',
                        'rightImage' => 'https://images.unsplash.com/photo-1534088568595-a066f410bcda?auto=format&fit=crop&w=150&q=80',
                        'rightAudio' => 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
                        'result' => 'Sunflower'
                    ],
                    [
                        'left' => 'Rain',
                        'leftImage' => 'https://images.unsplash.com/photo-1534274988757-a28bf1a57c17?auto=format&fit=crop&w=150&q=80',
                        'leftAudio' => 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
                        'right' => 'Bow',
                        'rightImage' => 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=150&q=80',
                        'rightAudio' => 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
                        'result' => 'Rainbow'
                    ],
                    [
                        'left' => 'Jelly',
                        'leftImage' => 'https://images.unsplash.com/photo-1582268611958-ebfd161ef9cf?auto=format&fit=crop&w=150&q=80',
                        'leftAudio' => 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
                        'right' => 'Fish',
                        'rightImage' => 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=150&q=80',
                        'rightAudio' => 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
                        'result' => 'Jellyfish'
                    ]
                ]
            ],
            'created_by' => null
        ]);

        // Writing with the image fill-in-the-blanks mode
        $writingAct = Activity::create([
            'title' => 'Demo Writing - Image Identification',
            'type' => 'writing',
            'data_json' => [
                'question' => 'Look at each image carefully and type its name correctly in English under it!',
                'mode' => 'image_fill',
                'pairs' => [
                    [
                        'leftImage' => 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=150&q=80', // dog
                        'leftAnswer' => 'dog',
                        'rightImage' => 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=150&q=80', // cat
                        'rightAnswer' => 'cat'
                    ],
                    [
                        'leftImage' => 'https://images.unsplash.com/photo-1534796636912-3b95b3ab5986?auto=format&fit=crop&w=150&q=80', // sun
                        'leftAnswer' => 'sun',
                        'rightImage' => 'https://images.unsplash.com/photo-1534088568595-a066f410bcda?auto=format&fit=crop&w=150&q=80', // flower
                        'rightAnswer' => 'flower'
                    ]
                ]
            ],
            'created_by' => null
        ]);

        // 5. Create Content Lesson Blocks
        $blocks = [
            [ "type" => "header", "data" => [ "text" => "Welcome to the New Interactive Features Showcase! 🚀", "level" => 2 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "In this demo test level, you can preview and verify all the newly integrated features for kids language learning activities. Experience standard text-to-speech spoken feedback, double-sided image-based matches with custom floating clouds, audio playback, and visual spelling test modes." ] ],
            
            [ "type" => "header", "data" => [ "text" => "1. MCQ Audio & Image Support 🔊", "level" => 3 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Each MCQ question and answer option now supports custom image displays and individual pronunciation speak buttons. Try clicking the speaker icons to hear their voice, or submit answers to trigger vocal right/wrong speech feedback." ] ],
            [
                'type' => 'activity',
                'data' => [
                    'type' => 'activity_reference',
                    'activityReferenceId' => $mcqAct->id
                ]
            ],

            [ "type" => "header", "data" => [ "text" => "2. Cloud Matching with Compound Result Cards ☁️", "level" => 3 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Our match-the-following activity now features a custom cloud layout theme, bounce-in entrance, gentle floating animations, and audio pronunciation icons. Connected correct elements merge together into visual compound result cards." ] ],
            [
                'type' => 'activity',
                'data' => [
                    'type' => 'activity_reference',
                    'activityReferenceId' => $matchAct->id
                ]
            ],

            [ "type" => "header", "data" => [ "text" => "3. Image-based writing fill-ups ✍️", "level" => 3 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Students can look at the images displayed in the grid and write their corresponding names underneath them. Results are automatically evaluated, showing green/red badges indicating correctness." ] ],
            [
                'type' => 'activity',
                'data' => [
                    'type' => 'activity_reference',
                    'activityReferenceId' => $writingAct->id
                ]
            ],
        ];

        // Delete old demo content
        DB::table('content_chapters')->where('chapter_id', $chapter->id)->delete();
        Content::where('name', 'like', 'Interactive Features Showcase%')->delete();

        $content = Content::create([
            'name' => 'Interactive Features Showcase',
            'title' => 'Interactive Features Showcase',
            'sort_order' => 1,
            'is_active' => true,
            'text_content' => json_encode(['time' => time(), 'blocks' => $blocks, 'version' => '2.29.1'], JSON_UNESCAPED_UNICODE)
        ]);

        DB::table('content_chapters')->insert([
            'content_id' => $content->id,
            'chapter_id' => $chapter->id,
            'sort_order' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}
