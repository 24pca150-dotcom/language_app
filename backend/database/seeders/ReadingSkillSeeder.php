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

class ReadingSkillSeeder extends Seeder
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
            ['code' => 'LVL-READING-SKILLS'],
            [
                'name' => 'Reading Skills',
                'description' => 'Reading Skills - Alphabet, vowels, consonants, and compound words.',
                'sort_order' => 3,
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
            ['code' => 'CHP-READING-BASICS'],
            [
                'name' => 'Reading Skill Basics',
                'description' => 'Master the alphabet, vowels, consonants, and compound words.',
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
            [ "type" => "header", "data" => [ "text" => "Welcome to Reading Skills! 📖", "level" => 2 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "In the previous component, we learnt about Speaking Skills and practised how to communicate our thoughts clearly and confidently. Now, let's dive into Reading Skills!" ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Reading is the ability to recognize letters, words, and sentences and understand their meaning. It is an essential language skill that helps learners acquire knowledge, improve vocabulary, and develop communication skills. Reading begins with identifying letters and sounds and gradually progresses to understanding words, phrases, and complete texts." ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Every reading journey begins with letters. Let’s start by exploring the English alphabet!" ] ],

            [ "type" => "header", "data" => [ "text" => "ENGLISH ALPHABETS", "level" => 2 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "The English alphabet consists of 26 letters, which are the building blocks of all English words. Each letter has an uppercase (capital) and lowercase (small) form." ] ],
            
            [
                "type" => "table",
                "data" => [
                    "withHeadings" => true,
                    "content" => [
                        ["Case", "Letters"],
                        ["Capital letters", "A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z"],
                        ["Small letters", "a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z"]
                    ]
                ]
            ],

            [ "type" => "header", "data" => [ "text" => "Task 1: Count the letters! 🔢", "level" => 2 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Read the given word carefully and choose the correct count of the letters in the word." ] ],
        ];

        // Clean up previous activities to avoid duplicates
        Activity::whereNull('tenant_id')->where(function ($q) {
            $q->where('title', 'like', 'Reading Task%')
              ->orWhere('title', 'like', 'Reading Jumbled%')
              ->orWhere('title', 'like', 'Compound Word Match%');
        })->delete();

        // 1. Task 1 Activities: Count letters (alternate between MCQ and Fill in Blanks)
        $task1Words = [
            ["On", 2], ["Cat", 3], ["Book", 4], ["Apple", 5], ["Garden", 6],
            ["Teacher", 7], ["Elephant", 8], ["Notebook", 8], ["Backpack", 8], ["Sunflower", 9]
        ];

        foreach ($task1Words as $idx => $item) {
            $word = $item[0];
            $count = $item[1];
            $title = "Reading Task 1 - Word " . ($idx + 1);

            if ($idx % 2 === 0) {
                // MCQ format
                $actJson = [
                    'question' => "How many letters are in the word \"{$word}\"?",
                    'options' => [
                        [ 'id' => 1, 'text' => (string)$count, 'is_correct' => true ],
                        [ 'id' => 2, 'text' => (string)($count + 1), 'is_correct' => false ],
                        [ 'id' => 3, 'text' => (string)($count - 1), 'is_correct' => false ]
                    ]
                ];
                $type = 'mcq';
            } else {
                // Fill Blanks format
                $actJson = [
                    'question' => "Fill in the correct count of letters for the word \"{$word}\".",
                    'text' => "{$word} is a [{$count}] (" . ($count - 1) . " / {$count} / " . ($count + 1) . ") letter word."
                ];
                $type = 'fill_blanks';
            }

            $act = Activity::updateOrCreate(
                ['title' => $title, 'tenant_id' => null],
                [
                    'type' => $type,
                    'data_json' => $actJson,
                    'created_by' => null
                ]
            );

            $blocks1[] = [
                'type' => 'activity',
                'data' => [
                    'type' => 'activity_reference',
                    'activityReferenceId' => $act->id
                ]
            ];
        }

        // Save Content 1
        DB::table('content_chapters')->where('chapter_id', $chapter->id)->delete();
        Content::where('name', 'like', 'Reading Skills Lesson%')->delete();

        $content1 = Content::create([
            'name' => 'Reading Skills Lesson - English Alphabet',
            'title' => 'Reading Lesson: English Alphabet',
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

        // Initialize blocks2 for Part 2 (Vowels & Consonants)
        $blocks2 = [
            [ "type" => "paragraph", "data" => [ "text" => "Now that we know the letters, let’s discover some special letters called vowels!" ] ],

            [ "type" => "header", "data" => [ "text" => "VOWELS", "level" => 2 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "• The English language has five vowels: <strong>A, E, I, O, U</strong>" ] ],
            [ "type" => "paragraph", "data" => [ "text" => "• It helps produce speech sounds with an open mouth and without blocking the flow of air." ] ],
            [ "type" => "paragraph", "data" => [ "text" => "• For example, when we pronounce the letter “e”, only the mouth opens but our lips, tongue, and teeth do not move." ] ],

            [ "type" => "header", "data" => [ "text" => "Example: Identify the Vowels in these words:", "level" => 3 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "• The vowel in the word <strong>Fish</strong> is “i”.<br>• The vowel in the word <strong>Eyes</strong> is “e”.<br>• The vowels in the word <strong>Apple</strong> are “a”, “e”.<br>• The vowels in the word <strong>Blue</strong> are “u”, “e”.<br>• The Vowels in the word <strong>Ice</strong> are “i”, “e”" ] ],

            [ "type" => "paragraph", "data" => [ "text" => "Great work identifying vowels! Now, let’s meet their partners—the consonants." ] ],

            [ "type" => "header", "data" => [ "text" => "CONSONANTS", "level" => 2 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "• There are 21 consonants in the English language, they are: <strong>B, C, D, F, G, H, J, K, L, M, N, P, Q, R, S, T, V, W, X, Y, Z</strong>" ] ],
            [ "type" => "paragraph", "data" => [ "text" => "• Consonant sounds are produced when the flow of air is partly or completely blocked by the lips, teeth, or tongue." ] ],
            [ "type" => "paragraph", "data" => [ "text" => "• Consonants are pronounced by moving different parts of our mouths such as lips, teeth, or tongue. For instance, when we pronounce the letter “l”, we have to move our lips to touch our palate." ] ],

            [ "type" => "header", "data" => [ "text" => "Example: Find the consonants in the following words:", "level" => 3 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "• The consonants in the word <strong>Sitting</strong> are “s”, “t”, “n”, “g”.<br>• The consonants in the word <strong>Stopped</strong> are “s”, “t”, “p”, “d”.<br>• The consonants in the word <strong>Drop</strong> are “d”, “r”, “p”.<br>• The consonants in the word <strong>Plan</strong> are “p”, “l”, “n”.<br>• The consonants in the word <strong>Kid</strong> are “k”, “d”." ] ],

            [ "type" => "header", "data" => [ "text" => "Task 2: Identify Vowels & Consonants! 🔍", "level" => 2 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Read each word carefully, then identify the correct set of vowels and consonants." ] ]
        ];

        // 2. Task 2 Activities: Vowels and Consonants
        $task2Data = [
            ["Cat", "a", "c, t"],
            ["Pen", "e", "p, n"],
            ["Fish", "i", "f, s, h"],
            ["Book", "o, o", "b, k"],
            ["Apple", "a, e", "p, p, l"],
            ["Tiger", "i, e", "t, g, r"],
            ["School", "o, o", "s, c, h, l"],
            ["Garden", "a, e", "g, r, d, n"],
            ["Orange", "o, a, e", "r, n, g"],
            ["Pencil", "e, i", "p, n, c, l"]
        ];

        foreach ($task2Data as $idx => $item) {
            $word = $item[0];
            $vowels = $item[1];
            $consonants = $item[2];
            $title = "Reading Task 2 - Word " . ($idx + 1);

            $actJson = [
                'question' => "Identify the Vowels and Consonants in the word: \"{$word}\"",
                'options' => [
                    [ 'id' => 1, 'text' => "Vowels: {$vowels} | Consonants: {$consonants}", 'is_correct' => true ],
                    [ 'id' => 2, 'text' => "Vowels: {$consonants} | Consonants: {$vowels}", 'is_correct' => false ]
                ]
            ];

            $act = Activity::updateOrCreate(
                ['title' => $title, 'tenant_id' => null],
                [
                    'type' => 'mcq',
                    'data_json' => $actJson,
                    'created_by' => null
                ]
            );

            $blocks2[] = [
                'type' => 'activity',
                'data' => [
                    'type' => 'activity_reference',
                    'activityReferenceId' => $act->id
                ]
            ];
        }

        $blocks2[] = [ "type" => "header", "data" => [ "text" => "Task 3: Unscramble the Jumbled Words! 🧩", "level" => 2 ] ];
        $blocks2[] = [ "type" => "paragraph", "data" => [ "text" => "Rearrange the given letters to form a meaningful word." ] ];

        // 3. Task 3 Activities: Jumbled Words
        $jumbledWords = [
            ["wolfre", "flower"], ["lcaned", "candle"], ["nirat", "train"], ["olocmn", "column"], ["tescal", "castle"],
            ["kormey", "monkey"], ["ridgeb", "bridge"], ["ronwcb", "brown"], ["tnegar", "garden"], ["nlitouma", "mountain"]
        ];

        foreach ($jumbledWords as $idx => $item) {
            $jumbled = $item[0];
            $correct = $item[1];
            $title = "Reading Jumbled Word " . ($idx + 1);

            $actJson = [
                'question' => "Rearrange the jumbled letters: \"{$jumbled}\"",
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

            $blocks2[] = [
                'type' => 'activity',
                'data' => [
                    'type' => 'activity_reference',
                    'activityReferenceId' => $act->id
                ]
            ];
        }

        // Save Content 2
        $content2 = Content::create([
            'name' => 'Reading Skills Lesson - Vowels & Consonants',
            'title' => 'Reading Lesson: Vowels & Consonants',
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

        // Initialize blocks3 for Part 3 (Compound Words)
        $blocks3 = [
            [ "type" => "header", "data" => [ "text" => "Discover Compound Words! 🔗", "level" => 2 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Did you know that some words are made by combining two smaller words? Let’s explore compound words!<br><br>A compound word is two or more words combined to express a single concept. The combined word often has a meaning that goes beyond the sum of its parts.<br><br>For example, a <strong>blackbird</strong> is a specific type of bird, not just any bird that's black. A <strong>greenhouse</strong> isn't simply a house that's green. It's a structure with a specific function." ] ],
            [ "type" => "header", "data" => [ "text" => "There are three types of compound words:", "level" => 3 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "1. <strong>Closed compound word</strong>: Combine two words into a single unit with no space or hyphen. Examples: notebook, sunflower, toothbrush.<br>2. <strong>Hyphenated compound word</strong>: Formed by joining two or more words with a hyphen (-). Examples: mother-in-law, editor-in-chief, part-time.<br>3. <strong>Open compound word</strong>: Two words that function as a single concept but are written with a space between them. Examples: ice cream, post office, high school." ] ],
            [ "type" => "header", "data" => [ "text" => "List of Closed Compound Words", "level" => 3 ] ]
        ];
        $closedList = [
            ["notebook", "football"], ["sunflower", "toothbrush"], ["rainbow", "classroom"],
            ["bedroom", "airport"], ["newspaper", "snowman"], ["cupcake", "firefly"],
            ["mailbox", "backpack"], ["basketball", "haircut"], ["bookshelf", "seashell"],
            ["keyboard", "moonlight"]
        ];
        $closedTable = [["Word 1", "Word 2"]];
        foreach ($closedList as $item) { $closedTable[] = $item; }
        $blocks3[] = [ "type" => "table", "data" => [ "withHeadings" => true, "content" => $closedTable ] ];

        $blocks3[] = [ "type" => "header", "data" => [ "text" => "List of Hyphenated Compound Words", "level" => 3 ] ];
        $hyphenatedList = [
            ["mother-in-law", "well-known"], ["check-in", "self-esteem"], ["runner-up", "sister-in-law"],
            ["father-in-law", "twenty-one"], ["part-time", "full-time"], ["up-to-date", "long-term"],
            ["short-term", "ice-cold"], ["world-class", "old-fashioned"], ["state-of-the-art", "high-speed"],
            ["editor-in-chief", "one-sided"]
        ];
        $hyphenatedTable = [["Word 1", "Word 2"]];
        foreach ($hyphenatedList as $item) { $hyphenatedTable[] = $item; }
        $blocks3[] = [ "type" => "table", "data" => [ "withHeadings" => true, "content" => $hyphenatedTable ] ];

        $blocks3[] = [ "type" => "header", "data" => [ "text" => "List of Open Compound Words", "level" => 3 ] ];
        $openList = [
            ["ice cream", "post office"], ["living room", "high school"], ["bus stop", "full moon"],
            ["real estate", "swimming pool"], ["coffee table", "police station"], ["hot dog", "science fiction"],
            ["washing machine", "dining room"], ["parking lot", "cell phone"], ["movie theatre", "fire station"],
            ["traffic light", "alarm clock"]
        ];
        $openTable = [["Word 1", "Word 2"]];
        foreach ($openList as $item) { $openTable[] = $item; }
        $blocks3[] = [ "type" => "table", "data" => [ "withHeadings" => true, "content" => $openTable ] ];

        $blocks3[] = [ "type" => "header", "data" => [ "text" => "Cloud Match Challenge! ☁️", "level" => 2 ] ];
        $blocks3[] = [ "type" => "paragraph", "data" => [ "text" => "Match words from the left and right columns to form correct compound words." ] ];

        // 4. Cloud Match Activities (Matching compound words)
        $matchPairs1 = [
            ['left' => 'Sun', 'right' => 'Flower'],
            ['left' => 'Tooth', 'right' => 'Brush'],
            ['left' => 'Rain', 'right' => 'Bow'],
            ['left' => 'Class', 'right' => 'Room'],
            ['left' => 'Foot', 'right' => 'Ball']
        ];
        $act1 = Activity::updateOrCreate(
            ['title' => 'Compound Word Match 1', 'tenant_id' => null],
            [
                'type' => 'match',
                'data_json' => [
                    'question' => 'Match to form Closed Compound words:',
                    'pairs' => $matchPairs1
                ],
                'created_by' => null
            ]
        );
        $blocks3[] = [ 'type' => 'activity', 'data' => [ 'type' => 'activity_reference', 'activityReferenceId' => $act1->id ] ];

        $matchPairs2 = [
            ['left' => 'Ice', 'right' => 'Cream'],
            ['left' => 'Post', 'right' => 'Office'],
            ['left' => 'Living', 'right' => 'Room'],
            ['left' => 'High', 'right' => 'School'],
            ['left' => 'Alarm', 'right' => 'Clock']
        ];
        $act2 = Activity::updateOrCreate(
            ['title' => 'Compound Word Match 2', 'tenant_id' => null],
            [
                'type' => 'match',
                'data_json' => [
                    'question' => 'Match to form Open Compound words:',
                    'pairs' => $matchPairs2
                ],
                'created_by' => null
            ]
        );
        $blocks3[] = [ 'type' => 'activity', 'data' => [ 'type' => 'activity_reference', 'activityReferenceId' => $act2->id ] ];

        $matchPairs3 = [
            ['left' => 'Mother', 'right' => 'In-law'],
            ['left' => 'Well', 'right' => 'Known'],
            ['left' => 'Part', 'right' => 'Time'],
            ['left' => 'Self', 'right' => 'Esteem'],
            ['left' => 'Cut', 'right' => 'Off']
        ];
        $act3 = Activity::updateOrCreate(
            ['title' => 'Compound Word Match 3', 'tenant_id' => null],
            [
                'type' => 'match',
                'data_json' => [
                    'question' => 'Match to form Hyphenated Compound words:',
                    'pairs' => $matchPairs3
                ],
                'created_by' => null
            ]
        );
        $blocks3[] = [ 'type' => 'activity', 'data' => [ 'type' => 'activity_reference', 'activityReferenceId' => $act3->id ] ];

        $blocks3[] = [ "type" => "header", "data" => [ "text" => "Keep reading and keep learning! 🌟", "level" => 2 ] ];
        $blocks3[] = [ "type" => "paragraph", "data" => [ "text" => "Excellent work! We have successfully completed our journey through the fundamentals of Reading Skills. Through these activities, you have strengthened your vocabulary, improved your word recognition skills, and enhanced your reading ability.<br><br>Remember, reading is the key to learning and knowledge. Every page you read takes you one step closer to becoming a better reader and communicator." ] ];

        $content3 = Content::create([
            'name' => 'Reading Skills Lesson - Compound Words',
            'title' => 'Reading Lesson: Compound Words',
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
    }
}
