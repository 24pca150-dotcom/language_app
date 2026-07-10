<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Course;
use App\Models\Level;
use App\Models\Chapter;
use App\Models\Content;
use App\Models\Package;
use Illuminate\Support\Facades\DB;

class EnglishCourseSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 1. Create a default package if not exists
        $package = Package::firstOrCreate(
            ['code' => 'PKG-ENGLISH-BEGINNER'],
            [
                'name' => 'English for Beginner Package',
                'description' => 'Complete package containing all English skill levels.',
                'is_active' => true,
            ]
        );

        // 2. Create the English Course
        $course = Course::firstOrCreate(
            ['name' => 'English for Beginner'],
            [
                'description' => 'Learn English step by step with writing, listening, reading, and speaking skills.',
                'is_active' => true,
            ]
        );

        // 3. Create Level: Grammar & Vocabulary
        $level = Level::firstOrCreate(
            ['code' => 'LVL-GRAMMAR-VOCAB'],
            [
                'name' => 'Grammar & Vocabulary',
                'description' => 'Master grammar, homophones, vocabulary, and basic language elements.',
                'sort_order' => 5,
                'is_active' => true,
            ]
        );

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

        // Map English Course Package to the single Tenant and Property
        $learningModes = \App\Models\LearningMode::whereIn('code', ['BEGINNER', 'CHILDEREN'])->get();
        if ($learningModes->isEmpty()) {
            $learningModes = \App\Models\LearningMode::all();
        }
        $learningModeIds = $learningModes->pluck('id')->toArray();

        $t = \App\Models\Tenant::where('tenant_code', 'SCH-001')->first() ?? \App\Models\Tenant::first();
        if ($t) {
            $property = \App\Models\Property::firstOrCreate(
                ['property_code' => 'PROP-SCH-001'],
                [
                    'tenant_id' => $t->id,
                    'property_name' => 'Ariga Public School Campus',
                    'location' => 'Virtual/Online',
                    'address' => 'Online Portal',
                    'max_users' => 500,
                    'is_active' => true,
                ]
            );

            DB::table('property_packages')->updateOrInsert(
                [
                    'property_id' => $property->id,
                    'package_id' => $package->id,
                ],
                [
                    'course_id' => $course->id,
                    'learning_mode_ids' => json_encode($learningModeIds),
                    'start_date' => now()->format('Y-m-d'),
                    'end_date' => now()->addYears(5)->format('Y-m-d'),
                    'is_active' => true,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]
            );
        }

        // 4. Create Chapter: Homophones
        $chapter = Chapter::firstOrCreate(
            ['code' => 'CHP-HOMOPHONES'],
            [
                'name' => 'Homophones',
                'description' => 'Learn about words that sound the same but have different meanings.',
                'sort_order' => 1,
                'is_active' => true,
            ]
        );

        // Link Level -> Chapter
        DB::table('level_chapter')->updateOrInsert(
            [
                'level_id' => $level->id,
                'chapter_id' => $chapter->id,
            ],
            [
                'sort_order' => 1,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]
        );

        // 5. Create Content (JSON structured to enable dot pagination)
        $jsonContent = [
            "blocks" => [
                [ "type" => "header", "data" => [ "text" => "Welcome to the World of Fun Listening!" ] ],
                [ "type" => "paragraph", "data" => [ "text" => "Listening is the first step in learning any language. Good listening helps us follow instructions, learn new words, and communicate confidently in English." ] ],
                [ "type" => "header", "data" => [ "text" => "What are Homophones?" ] ],
                [ "type" => "paragraph", "data" => [ "text" => "Have you ever heard two words that sound exactly the same but have different meanings and spellings? These are called <strong>Homophones</strong>." ] ],
                [ "type" => "list", "data" => [ "items" => ["<strong>HOMO</strong> means <em>same</em>", "<strong>PHONE</strong> means <em>sound</em>"] ] ],
                [ "type" => "header", "data" => [ "text" => "Examples:" ] ],
                [ "type" => "list", "data" => [ "items" => ["I can <strong>see</strong> the blue <strong>sea</strong> from my window.", "The <strong>sun</strong> is bright, and my <strong>son</strong> is playing outside.", "I will <strong>write</strong> my name on the <strong>right</strong> side of the page."] ] ],
                [ "type" => "header", "data" => [ "text" => "Common Homophones" ] ],
                [ "type" => "table", "data" => [ 
                    "withHeadings" => true, 
                    "content" => [
                        ["Homophones", "Meaning"],
                        ["Accept – Except", "Accept = receive; Except = leaving out"],
                        ["Affect – Effect", "Affect = influence; Effect = result"],
                        ["Ate – Eight", "Ate = past tense of eat; Eight = number 8"],
                        ["Break – Brake", "Break = separate into pieces; Brake = stops vehicle"],
                        ["Buy – Bye – By", "Buy = purchase; Bye = farewell; By = near"],
                        ["Hear – Here", "Hear = listen; Here = this place"],
                        ["Hole – Whole", "Hole = opening; Whole = complete"],
                        ["Know – No", "Know = understand; No = negative answer"],
                        ["Peace – Piece", "Peace = calmness; Piece = part"],
                        ["Right – Write", "Right = correct; Write = form words"],
                        ["Sea – See", "Sea = large water body; See = look"],
                        ["Son – Sun", "Son = boy child; Sun = star"],
                        ["There – Their", "There = place; Their = belonging to them"],
                        ["To – Too – Two", "To = direction; Too = also; Two = number 2"]
                    ] 
                ] ],
                [ "type" => "header", "data" => [ "text" => "Exercises" ] ],
                [ "type" => "paragraph", "data" => [ "text" => "Choose the correct word from the brackets:" ] ],
                [ "type" => "list", "data" => [ "items" => ["My friends said <strong>(bye / buy)</strong> before leaving.", "We saw a colourful <strong>(flower / flour)</strong>.", "I can <strong>(hear / here)</strong> music coming from the next room.", "My sister will <strong>(write / right)</strong> a poem.", "The children waited for an <strong>(hour / our)</strong>."] ] ],
                [ "type" => "paragraph", "data" => [ "text" => "<em>Fantastic work! Keep practicing and enjoy learning new words!</em>" ] ]
            ]
        ];

        // Ensure older contents are unlinked to avoid duplicates
        DB::table('content_chapters')->where('chapter_id', $chapter->id)->delete();
        Content::where('name', 'like', '%Homophones%')->delete();

        $content = Content::create([
            'name' => 'Homophones Lesson',
            'title' => 'Homophones Lesson',
            'sort_order' => 1,
            'is_active' => true,
            'text_content' => json_encode($jsonContent, JSON_UNESCAPED_UNICODE)
        ]);

        // Link Chapter -> Content
        DB::table('content_chapters')->insert([
            'content_id' => $content->id,
            'chapter_id' => $chapter->id,
            'sort_order' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // ---------------------------------------------------------
        // New Chapter: Sounds of Animals
        // ---------------------------------------------------------
        $animalChapter = Chapter::firstOrCreate(
            ['code' => 'CHP-ANIMAL-SOUNDS'],
            [
                'name' => 'Sounds of Animals',
                'description' => 'Listen and learn the amazing sounds of animals and birds.',
                'sort_order' => 2,
                'is_active' => true,
            ]
        );

        // Link Level -> Animal Chapter
        DB::table('level_chapter')->updateOrInsert(
            [
                'level_id' => $level->id,
                'chapter_id' => $animalChapter->id,
            ],
            [
                'sort_order' => 2,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]
        );

        // Create Content for Sounds of Animals
        $animalJsonContent = [
            "blocks" => [
                [ "type" => "header", "data" => [ "text" => "Hello little listeners!" ] ],
                [ "type" => "paragraph", "data" => [ "text" => "Welcome to the wonderful world of animal and bird sounds! Every sound around us tells a story. Listening carefully helps us learn, understand, and enjoy the beautiful sounds of nature." ] ],
                [ "type" => "header", "data" => [ "text" => "What is sound?" ] ],
                [ "type" => "paragraph", "data" => [ "text" => "Sound is a form of energy that we can hear. Animals and birds use different sounds to talk to one another, just like we use words. So, put on your listening ears and get ready for an exciting sound adventure! 🎶🐶🦜" ] ],
                [ "type" => "header", "data" => [ "text" => "Sounds of Animals & Birds" ] ],
                [ "type" => "table", "data" => [ 
                    "withHeadings" => true, 
                    "content" => [
                        ["Animal / Bird", "Sound"],
                        ["Bees", "buzz"],
                        ["Cats", "meow, purr"],
                        ["Cows", "moo"],
                        ["Dogs", "bark"],
                        ["Ducks", "quack"],
                        ["Frogs", "croak"],
                        ["Horses", "neigh"],
                        ["Lions", "roar"],
                        ["Monkeys", "chatter"],
                        ["Owls", "hoot"],
                        ["Pigs", "oink"],
                        ["Pigeons", "coo"],
                        ["Roosters", "crow"],
                        ["Sheep", "bleat"],
                        ["Snakes", "hiss"]
                    ] 
                ] ],
                [ "type" => "header", "data" => [ "text" => "Activity 1 – Listen and Identify" ] ],
                [ "type" => "paragraph", "data" => [ "text" => "Let’s see if you can identify the correct sound!" ] ],
                [ "type" => "list", "data" => [ "items" => [
                    "The baby chick began to <strong>(cheep / roar)</strong>.",
                    "In the jungle, the tiger started to <strong>(quack / growl)</strong>.",
                    "The snake hiding under the rock began to <strong>(hiss / moo)</strong>.",
                    "The elephant at the zoo gave a loud <strong>(squeak / trumpet)</strong>.",
                    "The sheep in the meadow began to <strong>(bleat / crow)</strong>."
                ] ] ],
                [ "type" => "paragraph", "data" => [ "text" => "Wonderful job, little listeners! 👏🎉 You are now ready for the interactive challenge!" ] ],
                [
                    "type" => "activity",
                    "data" => [
                        "type" => "mcq",
                        "question" => "Which animal makes the sound “Meow”?",
                        "options" => [
                            [ "id" => 1, "text" => "Dog", "is_correct" => false ],
                            [ "id" => 2, "text" => "Cat", "is_correct" => true ]
                        ]
                    ]
                ],
                [
                    "type" => "activity",
                    "data" => [
                        "type" => "mcq",
                        "question" => "Which bird makes the sound “Quack”?",
                        "options" => [
                            [ "id" => 1, "text" => "Duck", "is_correct" => true ],
                            [ "id" => 2, "text" => "Owl", "is_correct" => false ]
                        ]
                    ]
                ],
                [
                    "type" => "activity",
                    "data" => [
                        "type" => "mcq",
                        "question" => "Which animal makes the sound “Roar”?",
                        "options" => [
                            [ "id" => 1, "text" => "Lion", "is_correct" => true ],
                            [ "id" => 2, "text" => "Goat", "is_correct" => false ]
                        ]
                    ]
                ],
                [
                    "type" => "activity",
                    "data" => [
                        "type" => "mcq",
                        "question" => "Which animal makes the sound “Neigh”?",
                        "options" => [
                            [ "id" => 1, "text" => "Cow", "is_correct" => false ],
                            [ "id" => 2, "text" => "Horse", "is_correct" => true ]
                        ]
                    ]
                ],
                [
                    "type" => "activity",
                    "data" => [
                        "type" => "mcq",
                        "question" => "Which animal makes the sound “Hiss”?",
                        "options" => [
                            [ "id" => 1, "text" => "Duck", "is_correct" => false ],
                            [ "id" => 2, "text" => "Snake", "is_correct" => true ]
                        ]
                    ]
                ]
            ]
        ];

        // Ensure older contents are unlinked to avoid duplicates
        DB::table('content_chapters')->where('chapter_id', $animalChapter->id)->delete();
        Content::where('name', 'like', '%Sounds of Animals%')->delete();

        $animalContent = Content::create([
            'name' => 'Sounds of Animals Lesson',
            'title' => 'Sounds of Animals',
            'sort_order' => 1,
            'is_active' => true,
            'text_content' => json_encode($animalJsonContent, JSON_UNESCAPED_UNICODE)
        ]);

        // Link Chapter -> Content
        DB::table('content_chapters')->insert([
            'content_id' => $animalContent->id,
            'chapter_id' => $animalChapter->id,
            'sort_order' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}
