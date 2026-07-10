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
use App\Models\LearningMode;
use App\Models\Activity;
use Illuminate\Support\Facades\DB;

class SpeakingSkillSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 1. Get or Create Tenant
        $tenant = Tenant::firstOrCreate(
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

        // 2. Create Package
        $package = Package::firstOrCreate(
            ['code' => 'PKG-ENGLISH-BEGINNER'],
            [
                'name' => 'English for Beginner Package',
                'description' => 'Complete package containing all English skill levels.',
                'is_active' => true,
            ]
        );

        // 3. Create Course
        $course = Course::firstOrCreate(
            ['name' => 'English for Beginner'],
            [
                'description' => 'Learn English step by step with writing, listening, reading, and speaking skills.',
                'is_active' => true,
            ]
        );

        // 4. Create Level
        $level = Level::firstOrCreate(
            ['code' => 'LVL-SPEAKING-SKILLS'],
            [
                'name' => 'Speaking Skills',
                'description' => 'Speaking Skills - Parts of speech, sentence building, and emotional expressions.',
                'sort_order' => 4,
                'is_active' => true,
            ]
        );

        // 5. Map Course -> Package -> Level
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

        // 6. Map for the single Tenant and Property
        $learningModes = LearningMode::whereIn('code', ['BEGINNER', 'CHILDEREN'])->get();
        if ($learningModes->isEmpty()) {
            $learningModes = LearningMode::all();
        }
        $learningModeIds = $learningModes->pluck('id')->toArray();

        $t = Tenant::where('tenant_code', 'SCH-001')->first() ?? Tenant::first();
        if ($t) {
            $property = Property::firstOrCreate(
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

        // 7. Create Chapter
        $chapter = Chapter::firstOrCreate(
            ['code' => 'CHP-SPEAKING-BASICS'],
            [
                'name' => 'Speaking Skill Basics',
                'description' => 'Learn the parts of speech, word arrangement, and expressions of emotions.',
                'sort_order' => 1,
                'is_active' => true,
            ]
        );

        // Map Level -> Chapter
        DB::table('level_chapter')->updateOrInsert(
            ['level_id' => $level->id, 'chapter_id' => $chapter->id],
            ['sort_order' => 1, 'is_active' => true, 'created_at' => now(), 'updated_at' => now()]
        );

        // 8. Generate Content Blocks for Lesson Content
        $blocks1 = [
            [ "type" => "header", "data" => [ "text" => "Welcome to Speaking Skills! 🗣️", "level" => 2 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "We have explored listening activities and it is time to move to the next important language skill “Speaking”." ] ],
            [ "type" => "paragraph", "data" => [ "text" => "⮚ Speaking helps us express our thoughts, ideas, feelings, and experiences clearly. It develops confidence and enables children to communicate effectively with teachers, friends, and others in everyday situations. By practising speaking regularly, students can improve their pronunciation, fluency, vocabulary, and sentence formation." ] ],
            [ "type" => "paragraph", "data" => [ "text" => "⮚ From simple self-introductions to storytelling, role plays, conversations, and picture descriptions, speaking activities make learning English interactive and enjoyable. Through these activities, students will learn to speak with confidence, clarity, and creativity.<br><br>Let’s talk, express, and communicate with confidence!" ] ],

            [ "type" => "header", "data" => [ "text" => "PARTS OF SPEECH - PART 1", "level" => 2 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Words are like building blocks of sentences. Every word we use has a special job to do. These jobs are called Parts of Speech. Learning parts of speech helps us speak and write English correctly and creatively.<br><br>Let’s start by exploring Nouns, Pronouns, Verbs, and Adjectives!" ] ],

            [
                "type" => "table",
                "data" => [
                    "withHeadings" => true,
                    "content" => [
                        ["Part of Speech", "Definition", "Examples", "Example in Sentence"],
                        ["Noun (naming word)", "Used to identify a person, place, animal, thing, or idea.", "teacher, Chennai, book, tiger, honesty", "1. The teacher explained the lesson clearly.<br>2. Chennai is known for its heritage."],
                        ["Pronoun", "Used in place of a noun to avoid repeating the same noun.", "he, she, they, it, we, you, them, his", "1. He won the first prize.<br>2. She sings beautifully."],
                        ["Verb (action word)", "Shows what a person, animal, or thing does or its state.", "run, sing, jump, is, are", "1. The athletes run every morning.<br>2. The children love to sing."],
                        ["Adjective", "Describing word that gives info about noun or pronoun.", "beautiful, tall, red, clever, happy", "1. She wore a beautiful dress.<br>2. The tall boy plays basketball."]
                    ]
                ]
            ],

            [ "type" => "header", "data" => [ "text" => "Task 1: Read, Identify, and Speak 📣", "level" => 2 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Identify the part of speech of the underlined word(s) in each sentence, and read the sentence aloud clearly." ] ],
        ];

        // Clean up previous activities to avoid duplicates
        Activity::whereNull('tenant_id')->where(function ($q) {
            $q->where('title', 'like', 'Speaking Task%')
              ->orWhere('title', 'like', 'Speaking Jumbled%')
              ->orWhere('title', 'like', 'Interjection Match%');
        })->delete();

        // 9. Task 1 Activities: Parts of Speech MCQ
        $task1Exercises = [
            [
                'sentence' => "The <u>little</u> boy ran <u>quickly</u> to school.",
                'q' => "Identify the parts of speech for 'little' and 'quickly':",
                'opts' => [
                    ['text' => "little: Adjective, quickly: Adverb", 'correct' => true],
                    ['text' => "little: Verb, quickly: Noun", 'correct' => false],
                    ['text' => "little: Adverb, quickly: Adjective", 'correct' => false],
                ]
            ],
            [
                'sentence' => "<u>She</u> sang a beautiful song yesterday.",
                'q' => "Identify the part of speech for 'She':",
                'opts' => [
                    ['text' => "She: Pronoun", 'correct' => true],
                    ['text' => "She: Noun", 'correct' => false],
                    ['text' => "She: Verb", 'correct' => false],
                ]
            ],
            [
                'sentence' => "The cat slept <u>under</u> the table.",
                'q' => "Identify the part of speech for 'under':",
                'opts' => [
                    ['text' => "under: Preposition", 'correct' => true],
                    ['text' => "under: Adverb", 'correct' => false],
                    ['text' => "under: Adjective", 'correct' => false],
                ]
            ],
            [
                'sentence' => "<u>Wow!</u> The fireworks look amazing tonight.",
                'q' => "Identify the part of speech for 'Wow!':",
                'opts' => [
                    ['text' => "Wow!: Interjection", 'correct' => true],
                    ['text' => "Wow!: Conjunction", 'correct' => false],
                    ['text' => "Wow!: Noun", 'correct' => false],
                ]
            ],
            [
                'sentence' => "My brother and I played cricket <u>happily</u>.",
                'q' => "Identify the part of speech for 'happily':",
                'opts' => [
                    ['text' => "happily: Adverb", 'correct' => true],
                    ['text' => "happily: Adjective", 'correct' => false],
                    ['text' => "happily: Verb", 'correct' => false],
                ]
            ],
            [
                'sentence' => "The <u>old</u> man walked slowly along the road.",
                'q' => "Identify the part of speech for 'old':",
                'opts' => [
                    ['text' => "old: Adjective", 'correct' => true],
                    ['text' => "old: Noun", 'correct' => false],
                    ['text' => "old: Pronoun", 'correct' => false],
                ]
            ],
            [
                'sentence' => "Riya bought a red dress <u>and</u> a blue scarf.",
                'q' => "Identify the part of speech for 'and':",
                'opts' => [
                    ['text' => "and: Conjunction", 'correct' => true],
                    ['text' => "and: Preposition", 'correct' => false],
                    ['text' => "and: Interjection", 'correct' => false],
                ]
            ],
            [
                'sentence' => "The children are sitting <u>inside</u> the classroom.",
                'q' => "Identify the part of speech for 'inside':",
                'opts' => [
                    ['text' => "inside: Preposition", 'correct' => true],
                    ['text' => "inside: Verb", 'correct' => false],
                    ['text' => "inside: Adjective", 'correct' => false],
                ]
            ],
            [
                'sentence' => "<u>They</u> completed the project because the teacher encouraged them.",
                'q' => "Identify the part of speech for 'They':",
                'opts' => [
                    ['text' => "They: Pronoun", 'correct' => true],
                    ['text' => "They: Noun", 'correct' => false],
                    ['text' => "They: Verb", 'correct' => false],
                ]
            ],
            [
                'sentence' => "The bird flew <u>gracefully</u> across the sky.",
                'q' => "Identify the part of speech for 'gracefully':",
                'opts' => [
                    ['text' => "gracefully: Adverb", 'correct' => true],
                    ['text' => "gracefully: Adjective", 'correct' => false],
                    ['text' => "gracefully: Noun", 'correct' => false],
                ]
            ],
            [
                'sentence' => "<u>Hurray!</u> Our team won the football match.",
                'q' => "Identify the part of speech for 'Hurray!':",
                'opts' => [
                    ['text' => "Hurray!: Interjection", 'correct' => true],
                    ['text' => "Hurray!: Conjunction", 'correct' => false],
                    ['text' => "Hurray!: Verb", 'correct' => false],
                ]
            ],
            [
                'sentence' => "Arun carried a heavy bag <u>but</u> never complained.",
                'q' => "Identify the part of speech for 'but':",
                'opts' => [
                    ['text' => "but: Conjunction", 'correct' => true],
                    ['text' => "but: Preposition", 'correct' => false],
                    ['text' => "but: Noun", 'correct' => false],
                ]
            ],
            [
                'sentence' => "The baby is sleeping <u>peacefully</u> in the cradle.",
                'q' => "Identify the part of speech for 'peacefully':",
                'opts' => [
                    ['text' => "peacefully: Adverb", 'correct' => true],
                    ['text' => "peacefully: Adjective", 'correct' => false],
                    ['text' => "peacefully: Verb", 'correct' => false],
                ]
            ],
            [
                'sentence' => "The clever fox jumped <u>over</u> the fence.",
                'q' => "Identify the part of speech for 'over':",
                'opts' => [
                    ['text' => "over: Preposition", 'correct' => true],
                    ['text' => "over: Adverb", 'correct' => false],
                    ['text' => "over: Noun", 'correct' => false],
                ]
            ],
            [
                'sentence' => "<u>Ouch!</u> The sharp thorn hurt my finger.",
                'q' => "Identify the part of speech for 'Ouch!':",
                'opts' => [
                    ['text' => "Ouch!: Interjection", 'correct' => true],
                    ['text' => "Ouch!: Noun", 'correct' => false],
                    ['text' => "Ouch!: Adjective", 'correct' => false],
                ]
            ]
        ];

        $blocks2 = [];
        foreach ($task1Exercises as $idx => $ex) {
            $title = "Speaking Task 1 - Sentence " . ($idx + 1);
            $options = [];
            foreach ($ex['opts'] as $oIdx => $opt) {
                $options[] = [
                    'id' => $oIdx + 1,
                    'text' => $opt['text'],
                    'is_correct' => $opt['correct']
                ];
            }

            $actJson = [
                'question' => "Read aloud: \"{$ex['sentence']}\"\n\n{$ex['q']}",
                'options' => $options
            ];

            $act = Activity::updateOrCreate(
                ['title' => $title, 'tenant_id' => null],
                [
                    'type' => 'mcq',
                    'data_json' => $actJson,
                    'created_by' => null
                ]
            );

            if ($idx < 8) {
                $blocks1[] = [
                    'type' => 'activity',
                    'data' => [
                        'type' => 'activity_reference',
                        'activityReferenceId' => $act->id
                    ]
                ];
            } else {
                $blocks2[] = [
                    'type' => 'activity',
                    'data' => [
                        'type' => 'activity_reference',
                        'activityReferenceId' => $act->id
                    ]
                ];
            }
        }

        // Save Content 1
        DB::table('content_chapters')->where('chapter_id', $chapter->id)->delete();
        Content::where('name', 'like', 'Speaking Skills Lesson%')->delete();

        $content1 = Content::create([
            'name' => 'Speaking Skills Lesson - Parts of Speech Part 1',
            'title' => 'Speaking Lesson: Nouns, Pronouns, Verbs, Adjectives',
            'sort_order' => 1,
            'is_active' => true,
            'text_content' => json_encode(['time' => time(), 'blocks' => $blocks1, 'version' => '2.29.1'], JSON_UNESCAPED_UNICODE)
        ]);

        DB::table('content_chapters')->insert([
            'content_id' => $content1->id,
            'chapter_id' => $chapter->id,
            'sort_order' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Initialize blocks2 with the second half of Parts of Speech
        $blocks2Init = [
            [ "type" => "header", "data" => [ "text" => "PARTS OF SPEECH - PART 2", "level" => 2 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Now, let’s explore Adverbs, Prepositions, Conjunctions, and Interjections!" ] ],

            [
                "type" => "table",
                "data" => [
                    "withHeadings" => true,
                    "content" => [
                        ["Part of Speech", "Definition", "Examples", "Example in Sentence"],
                        ["Adverb", "Describes or modifies a verb, adjective, or another adverb.", "quickly, slowly, happily, very, loudly", "1. The boy answered quickly.<br>2. The old man walked slowly."],
                        ["Preposition", "Shows relationship between noun/pronoun and other words.", "in, on, under, between, near, besides", "1. The students are in the classroom.<br>2. The book is on the table."],
                        ["Conjunction", "Joining word used to connect words, phrases, or sentences.", "and, but, because, or, although", "1. Ravi and Priya participated.<br>2. I was tired, but I did homework."],
                        ["Interjection", "Expresses sudden emotions, feelings, or reactions.", "wow!, alas!, hurray!, ouch!, bravo!", "1. Wow! The artwork is amazing.<br>2. Ouch! I hurt my finger."]
                    ]
                ]
            ],

            [ "type" => "header", "data" => [ "text" => "Task 1 (Continued): Speak and Identify 📣", "level" => 2 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Read each sentence aloud clearly, and choose the correct part of speech for the underlined word." ] ]
        ];

        // Merge initial blocks2 with the activities generated in loop
        $blocks2 = array_merge($blocks2Init, $blocks2);

        // Save Content 2
        $content2 = Content::create([
            'name' => 'Speaking Skills Lesson - Parts of Speech Part 2',
            'title' => 'Speaking Lesson: Adverbs, Prepositions, Conjunctions, Interjections',
            'sort_order' => 2,
            'is_active' => true,
            'text_content' => json_encode(['time' => time(), 'blocks' => $blocks2, 'version' => '2.29.1'], JSON_UNESCAPED_UNICODE)
        ]);

        DB::table('content_chapters')->insert([
            'content_id' => $content2->id,
            'chapter_id' => $chapter->id,
            'sort_order' => 2,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Initialize blocks3 for Part 3 (Word Arrangement)
        $blocks3 = [
            [ "type" => "header", "data" => [ "text" => "Task 2: Word Arrangement 🧩", "level" => 2 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Rearrange the given words to form a grammatically correct sentence, then read the sentence aloud." ] ]
        ];

        // 10. Task 2 Activities: Word Arrangement
        $task2Sentences = [
            ["football / they / playing / are", "They are playing football."],
            ["reading / book / a / is / Rani", "Rani is reading a book."],
            ["the / barking / dog / is", "The dog is barking."],
            ["cake / baking / mother / a / is", "Mother is baking a cake."],
            ["school / we / to / going / are", "We are going to school."],
            ["birds / the / singing / are", "The birds are singing."],
            ["drawing / picture / a / I / am", "I am drawing a picture."],
            ["bicycle / his / riding / Arun / is", "Arun is riding his bicycle."],
            ["dancing / stage / on / girls / the / are", "The girls are dancing on the stage."],
            ["homework / completing / my / am / I", "I am completing my homework."]
        ];

        foreach ($task2Sentences as $idx => $item) {
            $jumbled = $item[0];
            $correct = $item[1];
            $title = "Speaking Jumbled Sentence " . ($idx + 1);

            $actJson = [
                'question' => "Rearrange the words to make a complete sentence: \"{$jumbled}\"",
                'text' => $correct
            ];

            $act = Activity::updateOrCreate(
                ['title' => $title, 'tenant_id' => null],
                [
                    'type' => 'word_arrange',
                    'data_json' => $actJson,
                    'created_by' => null
                ]
            );

            $blocks3[] = [
                'type' => 'activity',
                'data' => [
                    'type' => 'activity_reference',
                    'activityReferenceId' => $act->id
                ]
            ];
        }

        // Save Content 3
        $content3 = Content::create([
            'name' => 'Speaking Skills Lesson - Word Arrangement',
            'title' => 'Speaking Lesson: Word Arrangement',
            'sort_order' => 3,
            'is_active' => true,
            'text_content' => json_encode(['time' => time(), 'blocks' => $blocks3, 'version' => '2.29.1'], JSON_UNESCAPED_UNICODE)
        ]);

        DB::table('content_chapters')->insert([
            'content_id' => $content3->id,
            'chapter_id' => $chapter->id,
            'sort_order' => 3,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Initialize blocks4 for Part 4 (Interjections Expressions Match)
        $blocks4 = [
            [ "type" => "header", "data" => [ "text" => "Task 3: Match the Expressions! 🗣️", "level" => 2 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Interjections are words or short expressions used to show sudden feelings or emotions. They are often followed by an exclamation mark (!). Observe the situations and match them to the correct Interjection." ] ]
        ];

        // 11. Task 3 Activity: Matching
        $matchPairs = [
            ['left' => 'Sudden pain', 'right' => 'OUCH!'],
            ['left' => 'Surprise or admiration', 'right' => 'WOW!'],
            ['left' => 'Joy, success or celebration', 'right' => 'HURRAY!'],
            ['left' => 'Sadness, grief or regret', 'right' => 'ALAS!'],
            ['left' => 'Praise and appreciation', 'right' => 'BRAVO!'],
            ['left' => 'Mistake or accident', 'right' => 'OOPS!'],
            ['left' => 'Asking for silence', 'right' => 'SHH!']
        ];

        $actMatch = Activity::updateOrCreate(
            ['title' => 'Interjection Match', 'tenant_id' => null],
            [
                'type' => 'match',
                'data_json' => [
                    'question' => 'Match each situation/feeling with its correct Interjection:',
                    'pairs' => $matchPairs
                ],
                'created_by' => null
            ]
        );
        $blocks4[] = [ 'type' => 'activity', 'data' => [ 'type' => 'activity_reference', 'activityReferenceId' => $actMatch->id ] ];

        $blocks4[] = [ "type" => "header", "data" => [ "text" => "Happy Speaking! 🌟", "level" => 2 ] ];
        $blocks4[] = [ "type" => "paragraph", "data" => [ "text" => "Hope you had great fun and enjoyed all the activities. Open your mouth and speak in English confidently to improve your speaking skills. Bye!" ] ];

        // Save Content 4
        $content4 = Content::create([
            'name' => 'Speaking Skills Lesson - Interjection Match',
            'title' => 'Speaking Lesson: Interjections Match',
            'sort_order' => 4,
            'is_active' => true,
            'text_content' => json_encode(['time' => time(), 'blocks' => $blocks4, 'version' => '2.29.1'], JSON_UNESCAPED_UNICODE)
        ]);

        DB::table('content_chapters')->insert([
            'content_id' => $content4->id,
            'chapter_id' => $chapter->id,
            'sort_order' => 4,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}
