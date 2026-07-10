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
use App\Models\Assessment;
use Illuminate\Support\Facades\DB;

class WritingSkillSeeder extends Seeder
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
            ['code' => 'LVL-WRITING-SKILLS'],
            [
                'name' => 'Writing Skills',
                'description' => 'Build a strong foundation in writing: singular & plural nouns and gerunds.',
                'sort_order' => 1,
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
        // Lookup learning mode codes: BEGINNER, CHILDEREN
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


        // 8. Create Chapters
        $chapter1 = Chapter::firstOrCreate(
            ['code' => 'CHP-SINGULAR-PLURAL'],
            [
                'name' => 'Singular & Plural Nouns',
                'description' => 'Understand and form singular and plural words in English.',
                'sort_order' => 1,
                'is_active' => true,
            ]
        );

        $chapter2 = Chapter::firstOrCreate(
            ['code' => 'CHP-GERUNDS'],
            [
                'name' => 'Gerunds',
                'description' => 'Learn verb forms ending in -ing that behave as nouns.',
                'sort_order' => 2,
                'is_active' => true,
            ]
        );

        // 9. Map Level -> Chapters
        DB::table('level_chapter')->updateOrInsert(
            ['level_id' => $level->id, 'chapter_id' => $chapter1->id],
            ['sort_order' => 1, 'is_active' => true, 'created_at' => now(), 'updated_at' => now()]
        );
        DB::table('level_chapter')->updateOrInsert(
            ['level_id' => $level->id, 'chapter_id' => $chapter2->id],
            ['sort_order' => 2, 'is_active' => true, 'created_at' => now(), 'updated_at' => now()]
        );

        // 10. Generate Content Blocks for Chapter 1: Singular & Plural Nouns
        $blocks1a = [
            [ "type" => "header", "data" => [ "text" => "Welcome to Writing Skills! 👋", "level" => 2 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Hi, Learners! Welcome to Writing Skills! Have you ever wondered how books, stories, letters, messages, and even social media posts are created? They all begin with one important skill—writing." ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Writing is more than putting words on paper. It helps us express our ideas, feelings, opinions, and creativity. Whether you're writing a sentence, an email, or a story, good writing helps others understand you clearly." ] ],
            [ "type" => "paragraph", "data" => [ "text" => "In this level, you will build a strong foundation in writing by learning:<br>• <strong>Singular and Plural Nouns</strong><br>• <strong>Gerunds</strong>" ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Let's begin this exciting journey together! Before we become good writers, we must first learn how words work. Let's start with one of the basic building blocks of writing—Singular and Plural Nouns." ] ],
            
            [ "type" => "header", "data" => [ "text" => "SINGULAR & PLURAL", "level" => 2 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Understanding singular and plural words is an important part of learning English grammar. Knowing how to recognize, form, and use them correctly helps us communicate clearly and accurately." ] ],
            [ "type" => "paragraph", "data" => [ "text" => "<strong>Definition:</strong> Singular and Plural Words tell us whether we are talking about one person, place, animal, thing, or idea, or more than one. A singular word refers to one, while a plural word refers to two or more. In most cases, plural words are formed by adding -s or -es to the singular form, though some words follow different rules. Learning singular and plural forms helps us use English correctly in both speaking and writing." ] ],
            [ "type" => "paragraph", "data" => [ "text" => "<strong>Eg:</strong> Book – Books, Box – Boxes." ] ],
            
            [ "type" => "header", "data" => [ "text" => "Regular Nouns", "level" => 3 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "<strong>i. Most singular nouns form the plural by adding -s.</strong>" ] ],
            [ "type" => "table", "data" => [
                "withHeadings" => true,
                "content" => [
                    ["Singular", "Plural"],
                    ["Boat", "boats"],
                    ["house", "houses"],
                    ["Cat", "cats"],
                    ["river", "rivers"]
                ]
            ] ],
            
            [ "type" => "paragraph", "data" => [ "text" => "<strong>ii. A singular noun ending in s, x, z, ch, sh makes the plural by adding -es.</strong>" ] ],
            [ "type" => "table", "data" => [
                "withHeadings" => true,
                "content" => [
                    ["Singular", "Plural"],
                    ["Bus", "buses"],
                    ["Wish", "wishes"],
                    ["pitch", "pitches"],
                    ["Box", "boxes"]
                ]
            ] ],

            [ "type" => "paragraph", "data" => [ "text" => "<strong>iii. A singular noun ending in a consonant and then y makes the plural by dropping the y and adding -ies.</strong>" ] ],
            [ "type" => "table", "data" => [
                "withHeadings" => true,
                "content" => [
                    ["Singular", "Plural"],
                    ["penny", "pennies"],
                    ["Spy", "spies"],
                    ["Baby", "babies"],
                    ["City", "cities"],
                    ["daisy", "daisies"]
                ]
            ] ],

            [ "type" => "header", "data" => [ "text" => "Ready for Your First Challenge? 🎯", "level" => 2 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "You've learned the rules of regular singular and plural nouns. Now let's see how well you can use them!" ] ]
        ];

        // Clean up old activities to avoid duplicates
        \App\Models\Activity::whereNull('tenant_id')->where(function ($q) {
            $q->where('title', 'like', 'Regular Plurals%')
              ->orWhere('title', 'like', 'Irregular Plurals%')
              ->orWhere('title', 'like', 'Gerund spelling%')
              ->orWhere('title', 'like', 'Gerund sentence%');
        })->delete();

        $chapter1Activities = [
            [
                'title' => 'Regular Plurals - Exercise 1',
                'type' => 'mcq',
                'data_json' => [
                    'question' => '<strong>Regular Plurals - Exercise 1:</strong> Choose the correct plural forms of: <strong>boy</strong>, <strong>park</strong>, and <strong>friend</strong>.',
                    'options' => [
                        [ 'id' => 1, 'text' => 'boys, parks, friends', 'is_correct' => true ],
                        [ 'id' => 2, 'text' => 'boyes, parkes, friendes', 'is_correct' => false ]
                    ]
                ]
            ],
            [
                'title' => 'Regular Plurals - Exercise 2',
                'type' => 'fill_blanks',
                'data_json' => [
                    'question' => '<strong>Regular Plurals - Exercise 2:</strong> Write the plural form of the words in brackets to complete the sentence.',
                    'text' => 'He carried a [boxes] (box) filled with [toys] (toy), two [brushes] (brush), and three [watches] (watch).'
                ]
            ],
            [
                'title' => 'Regular Plurals - Exercise 3',
                'type' => 'word_arrange',
                'data_json' => [
                    'question' => '<strong>Regular Plurals - Exercise 3:</strong> Unscramble the words to make a correct sentence containing plurals.',
                    'text' => 'The kids saw three foxes in the bushes.'
                ]
            ],
            [
                'title' => 'Irregular Plurals - Exercise 4',
                'type' => 'match',
                'data_json' => [
                    'question' => '<strong>Irregular Plurals:</strong> Match the singular noun with its correct irregular plural.',
                    'pairs' => [
                        [ 'left' => 'child', 'right' => 'children' ],
                        [ 'left' => 'woman', 'right' => 'women' ],
                        [ 'left' => 'mouse', 'right' => 'mice' ],
                        [ 'left' => 'foot', 'right' => 'feet' ]
                    ]
                ]
            ],
            [
                'title' => 'Irregular Plurals - Exercise 5',
                'type' => 'mcq',
                'data_json' => [
                    'question' => '<strong>Irregular Plurals - Exercise 5:</strong> Choose the correct plural forms of: <strong>leaf</strong>, <strong>wolf</strong>, <strong>knife</strong>, <strong>loaf</strong>, and <strong>life</strong>.',
                    'options' => [
                        [ 'id' => 1, 'text' => 'leaves, wolves, knives, loaves, lives', 'is_correct' => true ],
                        [ 'id' => 2, 'text' => 'leafs, wolfs, knifes, loafs, lifes', 'is_correct' => false ]
                    ]
                ]
            ]
        ];

        $blocks1b = [];
        foreach ($chapter1Activities as $idx => $actData) {
            $act = \App\Models\Activity::updateOrCreate(
                ['title' => $actData['title'], 'tenant_id' => null],
                [
                    'type' => $actData['type'],
                    'data_json' => $actData['data_json'],
                    'created_by' => null
                ]
            );

            if ($idx < 3) {
                $blocks1a[] = [
                    'type' => 'activity',
                    'data' => [
                        'type' => 'activity_reference',
                        'activityReferenceId' => $act->id
                    ]
                ];
            } else {
                $blocks1b[] = [
                    'type' => 'activity',
                    'data' => [
                        'type' => 'activity_reference',
                        'activityReferenceId' => $act->id
                    ]
                ];
            }
        }

        // Save Content 1a (Regular Nouns)
        DB::table('content_chapters')->where('chapter_id', $chapter1->id)->delete();
        Content::where('name', 'like', 'Singular & Plural Nouns Lesson%')->delete();

        $content1a = Content::create([
            'name' => 'Singular & Plural Nouns Lesson - Regular',
            'title' => 'Singular & Plural: Regular Nouns',
            'sort_order' => 1,
            'is_active' => true,
            'text_content' => json_encode(['time' => time(), 'blocks' => $blocks1a, 'version' => '2.29.1'], JSON_UNESCAPED_UNICODE)
        ]);

        DB::table('content_chapters')->insert([
            'content_id' => $content1a->id,
            'chapter_id' => $chapter1->id,
            'sort_order' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Initialize blocks1b with the Irregular Nouns explanations!
        $blocks1bInit = [
            [ "type" => "header", "data" => [ "text" => "Irregular Nouns", "level" => 3 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "<strong>i. There are some irregular noun plurals. The most common ones are listed below.</strong>" ] ],
            [ "type" => "table", "data" => [
                "withHeadings" => true,
                "content" => [
                    ["Singular", "Plural"],
                    ["woman", "women"],
                    ["Man", "men"],
                    ["child", "children"],
                    ["tooth", "teeth"],
                    ["foot", "feet"],
                    ["person", "people"],
                    ["leaf", "leaves"],
                    ["mouse", "mice"],
                    ["goose", "geese"],
                    ["Half", "halves"],
                    ["knife", "knives"],
                    ["Wife", "wives"],
                    ["Life", "lives"],
                    ["Elf", "elves"],
                    ["Loaf", "loaves"],
                    ["potato", "potatoes"],
                    ["tomato", "tomatoes"],
                    ["cactus", "cacti"],
                    ["focus", "foci"],
                    ["fungus", "fungi"],
                    ["nucleus", "nuclei"],
                    ["syllabus", "syllabi/syllabuses"],
                    ["analysis", "analyses"],
                    ["diagnosis", "diagnoses"],
                    ["oasis", "oases"],
                    ["thesis", "theses"],
                    ["crisis", "crises"],
                    ["phenomenon", "phenomena"],
                    ["criterion", "criteria"],
                    ["datum", "data"]
                ]
            ] ],

            [ "type" => "paragraph", "data" => [ "text" => "<strong>ii. Some nouns have the same form in the singular and the plural.</strong>" ] ],
            [ "type" => "table", "data" => [
                "withHeadings" => true,
                "content" => [
                    ["Singular", "Plural"],
                    ["sheep", "sheep"],
                    ["Fish", "fish"],
                    ["Deer", "deer"],
                    ["species", "species"],
                    ["aircraft", "aircraft"]
                ]
            ] ],

            [ "type" => "header", "data" => [ "text" => "Irregular Verb/Noun Agreement", "level" => 3 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "<strong>i. Some nouns have a plural form but take a singular verb.</strong>" ] ],
            [ "type" => "table", "data" => [
                "withHeadings" => true,
                "content" => [
                    ["Plural nouns used with a singular verb", "Sentence"],
                    ["news", "The news is at 6.30 p.m."],
                    ["athletics", "Athletics is good for young people."],
                    ["linguistics", "Linguistics is the study of language."],
                    ["darts", "Darts is a popular game in England."],
                    ["Billiards", "Billiards is played all over the world."]
                ]
            ] ],

            [ "type" => "paragraph", "data" => [ "text" => "<strong>ii. Some nouns have a fixed fixed plural form and take a plural verb.</strong> They are not used in the singular, or they have a different meaning in the singular. Nouns like this include: <em>trousers, jeans, glasses, savings, thanks, steps, stairs, customs, congratulations, tropics, wages, spectacles, outskirts, goods, wits</em>." ] ],
            [ "type" => "table", "data" => [
                "withHeadings" => true,
                "content" => [
                    ["Plural noun with plural verb", "Sentence"],
                    ["Trousers", "My trousers are too tight."],
                    ["Jeans", "Her jeans are black."],
                    ["Glasses", "Those glasses are his."]
                ]
            ] ],

            [ "type" => "header", "data" => [ "text" => "Ready for Irregular Plurals Challenge? 🎯", "level" => 2 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Let's check how well you understand irregular plural forms!" ] ]
        ];

        $blocks1b = array_merge($blocks1bInit, $blocks1b);

        // Save Content 1b
        $content1b = Content::create([
            'name' => 'Singular & Plural Nouns Lesson - Irregular',
            'title' => 'Singular & Plural: Irregular Nouns',
            'sort_order' => 2,
            'is_active' => true,
            'text_content' => json_encode(['time' => time(), 'blocks' => $blocks1b, 'version' => '2.29.1'], JSON_UNESCAPED_UNICODE)
        ]);

        DB::table('content_chapters')->insert([
            'content_id' => $content1b->id,
            'chapter_id' => $chapter1->id,
            'sort_order' => 2,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // 11. Generate Content Blocks for Chapter 2: Gerunds
        $blocks2a = [
            [ "type" => "header", "data" => [ "text" => "Welcome to the World of Gerunds! 🌟", "level" => 2 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "A gerund is a verb form that ends in -ing and functions as a noun in a sentence. Although it is formed from a verb, it can act as the subject, object, or complement of a sentence." ] ],
            
            [ "type" => "header", "data" => [ "text" => "Examples of Gerund Functions:", "level" => 3 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "1. <strong>Reading</strong> is my favourite hobby. (Subject)<br>2. She enjoys <strong>painting</strong>. (Object)<br>3. My favourite activity is <strong>swimming</strong>. (Subject Complement)<br>4. They are interested in <strong>learning</strong> new languages. (Object of a preposition)" ] ],

            [ "type" => "header", "data" => [ "text" => "a) The Gerund as the Subject of the sentence", "level" => 3 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "• <strong>Eating</strong> people is wrong.<br>• <strong>Hunting</strong> tigers is dangerous.<br>• <strong>Flying</strong> makes me nervous.<br>• <strong>Brushing</strong> your teeth is important.<br>• <strong>Smoking</strong> causes lung cancer." ] ],

            [ "type" => "header", "data" => [ "text" => "b) The Gerund as the Complement of the verb 'to be'", "level" => 3 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "• One of his duties is <strong>attending</strong> meetings.<br>• The hardest thing about learning English is <strong>understanding</strong> the gerund.<br>• One of life's pleasures is <strong>having</strong> breakfast in bed." ] ],

            [ "type" => "header", "data" => [ "text" => "c) The Gerund after Prepositions", "level" => 3 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "The gerund must be used when a verb comes after a preposition. This is also true of certain expressions ending in a preposition, for example the expressions <em>in spite of</em> & <em>there's no point in</em>.<br>• Can you sneeze without <strong>opening</strong> your mouth?<br>• She is good at <strong>painting</strong>.<br>• She avoided him by <strong>walking</strong> on the opposite side of the road.<br>• We arrived in Madrid after <strong>driving</strong> all night.<br>• My father decided against <strong>postponing</strong> his trip to Hungary.<br>• There's no point in <strong>waiting</strong>.<br>• In spite of <strong>missing</strong> the train, we arrived on time." ] ],

            [ "type" => "header", "data" => [ "text" => "d) The Gerund after Phrasal Verbs", "level" => 3 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Phrasal verbs are composed of a verb + preposition or adverb. Examples:<br>• When will you give up <strong>smoking</strong>?<br>• She always puts off <strong>going</strong> to the dentist.<br>• He kept on <strong>asking</strong> for money.<br>• Jim ended up <strong>buying</strong> a new TV after his old one broke." ] ],
            [ "type" => "paragraph", "data" => [ "text" => "There are some phrasal verbs that include the word 'to' as a preposition, e.g., <em>to look forward to, to take to, to be accustomed to, to get around to, & to be used to</em>. If you can put the pronoun 'it' after 'to' and it makes sense, 'to' is a preposition and must be followed by a gerund:<br>• I look forward to <strong>hearing</strong> from you soon. (I look forward to <em>it</em>.)<br>• I am used to <strong>waiting</strong> for buses. (I am used to <em>it</em>.)<br>• She didn't really take to <strong>studying</strong> English. (She didn't really take to <em>it</em>.)<br>• When will you get around to <strong>mowing</strong> the grass? (When will you get around to <em>it</em>?)" ] ],

            [ "type" => "header", "data" => [ "text" => "Task 2: Gerund Galley! 🔍", "level" => 2 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Let's Think Like Grammar Detectives! Identify the action and write the correct gerund form of the verb." ] ]
        ];

        $chapter2Activities = [
            [
                'title' => 'Gerund spelling - Exercise 1',
                'type' => 'mcq',
                'data_json' => [
                    'question' => 'Identify the correct gerund spelling of the verb: <strong>Mop</strong>',
                    'options' => [
                        [ 'id' => 1, 'text' => 'Mopping', 'is_correct' => true ],
                        [ 'id' => 2, 'text' => 'Moping', 'is_correct' => false ]
                    ]
                ]
            ],
            [
                'title' => 'Gerund spelling - Exercise 2',
                'type' => 'match',
                'data_json' => [
                    'question' => 'Match the root verb on the left with its correct gerund spelling on the right.',
                    'pairs' => [
                        [ 'left' => 'paint', 'right' => 'painting' ],
                        [ 'left' => 'write', 'right' => 'writing' ],
                        [ 'left' => 'dance', 'right' => 'dancing' ],
                        [ 'left' => 'sing', 'right' => 'singing' ]
                    ]
                ]
            ],
            [
                'title' => 'Gerund spelling - Exercise 3',
                'type' => 'word_arrange',
                'data_json' => [
                    'question' => 'Unscramble the words to make a correct sentence containing a gerund.',
                    'text' => 'Reading books is one of life\'s pleasures.'
                ]
            ]
        ];

        foreach ($chapter2Activities as $actData) {
            $act = \App\Models\Activity::updateOrCreate(
                ['title' => $actData['title'], 'tenant_id' => null],
                [
                    'type' => $actData['type'],
                    'data_json' => $actData['data_json'],
                    'created_by' => null
                ]
            );

            $blocks2a[] = [
                'type' => 'activity',
                'data' => [
                    'type' => 'activity_reference',
                    'activityReferenceId' => $act->id
                ]
            ];
        }

        // Save Content 2a
        DB::table('content_chapters')->where('chapter_id', $chapter2->id)->delete();
        Content::where('name', 'like', 'Gerunds Lesson%')->delete();

        $content2a = Content::create([
            'name' => 'Gerunds Lesson - Part 1',
            'title' => 'Gerunds: Introduction & Spelling',
            'sort_order' => 1,
            'is_active' => true,
            'text_content' => json_encode(['time' => time(), 'blocks' => $blocks2a, 'version' => '2.29.1'], JSON_UNESCAPED_UNICODE)
        ]);

        DB::table('content_chapters')->insert([
            'content_id' => $content2a->id,
            'chapter_id' => $chapter2->id,
            'sort_order' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Initialize blocks2b for Part 2
        $blocks2b = [
            [ "type" => "header", "data" => [ "text" => "e) The Gerund in Compound Nouns", "level" => 3 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "In compound nouns using the gerund, it is clear that the meaning is that of a noun, not of a continuous verb. For example, a <em>swimming pool</em> is a pool for swimming in, not a pool that is swimming.<br>• I am giving Sally a <strong>driving</strong> lesson.<br>• They have a <strong>swimming</strong> pool in their back yard.<br>• I bought some new <strong>running</strong> shoes." ] ],

            [ "type" => "header", "data" => [ "text" => "f) The Gerund after some Expressions", "level" => 3 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "The gerund is necessary after the expressions <em>can't help, can't stand, to be worth, & it's no use</em>.<br>• She couldn't help <strong>falling</strong> in love with him.<br>• I can't stand <strong>being</strong> stuck in traffic jams.<br>• It's no use <strong>trying</strong> to escape.<br>• It might be worth <strong>phoning</strong> the station to check the time of the train." ] ],

            [ "type" => "header", "data" => [ "text" => "Task 2B: Complete the Sentence 🎯", "level" => 2 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Choose or fill the correct gerund answer for each sentence." ] ]
        ];

        $exercises = [
            ["________ every day keeps us healthy.", "Running", "Run"],
            ["My sister enjoys ________.", "Painting", "Paint"],
            ["We are interested in ________ English.", "Learning", "Learn"],
            ["________ is my favourite hobby.", "Reading", "Read"],
            ["I like ________ in the morning.", "Walking", "Walk"],
            ["They finished ________ the project on time.", "Writing", "Write"],
            ["My father loves ________ books.", "Reading", "Read"],
            ["She is good at ________ songs.", "Singing", "Sing"],
            ["We practised ________ before the competition.", "Dancing", "Dance"],
            ["He avoids ________ late at night.", "Driving", "Drive"],
            ["My grandmother enjoys ________ flowers.", "Gardening", "Garden"],
            ["The children started ________ after the bell rang.", "Laughing", "Laugh"],
            ["I prefer ________ to watching television.", "Cooking", "Cook"],
            ["They are excited about ________ a new language.", "Learning", "Learn"],
            ["She spends her weekends ________ with her friends.", "Shopping", "Shop"]
        ];

        foreach ($exercises as $idx => $ex) {
            $title = "Gerund sentence exercise - " . ($idx + 1);
            if ($idx % 2 === 0) {
                $actJson = [
                    'question' => 'Sentence ' . ($idx + 1) . ': ' . $ex[0],
                    'options' => [
                        [ 'id' => 1, 'text' => $ex[1], 'is_correct' => true ],
                        [ 'id' => 2, 'text' => $ex[2], 'is_correct' => false ]
                    ]
                ];
                $type = 'mcq';
            } else {
                // Replace "________" with "[Gerund]" for fill_blanks format
                $blankText = str_replace("________", "[" . $ex[1] . "]", $ex[0]);
                $actJson = [
                    'question' => 'Sentence ' . ($idx + 1) . ': Fill in the blank with the correct gerund form of verb <strong>' . strtolower($ex[2]) . '</strong>.',
                    'text' => $blankText
                ];
                $type = 'fill_blanks';
            }

            $act = \App\Models\Activity::updateOrCreate(
                ['title' => $title, 'tenant_id' => null],
                [
                    'type' => $type,
                    'data_json' => $actJson,
                    'created_by' => null
                ]
            );

            $blocks2b[] = [
                'type' => 'activity',
                'data' => [
                    'type' => 'activity_reference',
                    'activityReferenceId' => $act->id
                ]
            ];
        }

        // Save Content 2b
        $content2b = Content::create([
            'name' => 'Gerunds Lesson - Part 2',
            'title' => 'Gerunds: Application & Practice',
            'sort_order' => 2,
            'is_active' => true,
            'text_content' => json_encode(['time' => time(), 'blocks' => $blocks2b, 'version' => '2.29.1'], JSON_UNESCAPED_UNICODE)
        ]);

        DB::table('content_chapters')->insert([
            'content_id' => $content2b->id,
            'chapter_id' => $chapter2->id,
            'sort_order' => 2,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // 15. Create Assessments & Questions for the Chapters
        Assessment::where('chapter_id', $chapter1->id)->delete();
        Assessment::where('chapter_id', $chapter2->id)->delete();

        // Singular & Plural Quiz
        $assessment1 = Assessment::create([
            'level_id' => $level->id,
            'chapter_id' => $chapter1->id,
            'title' => 'Singular & Plural Nouns Quiz',
            'description' => 'Test your understanding of singular and plural nouns rules.',
            'pass_percentage' => 70.00,
            'total_marks' => 10,
            'passing_marks' => 7,
            'duration_minutes' => 15,
            'is_mandatory' => true,
            'is_active' => true,
        ]);

        $q1 = $assessment1->questions()->create([
            'question_text' => 'What is the plural form of "child"?',
            'question_type' => 'multiple_choice',
            'sort_order' => 1,
        ]);
        $q1->options()->createMany([
            ['option_text' => 'children', 'is_correct' => true, 'sort_order' => 1],
            ['option_text' => 'childs', 'is_correct' => false, 'sort_order' => 2],
            ['option_text' => 'childrens', 'is_correct' => false, 'sort_order' => 3],
        ]);

        $q2 = $assessment1->questions()->create([
            'question_text' => 'Which of the following is the correct plural form of "wife"?',
            'question_type' => 'multiple_choice',
            'sort_order' => 2,
        ]);
        $q2->options()->createMany([
            ['option_text' => 'wifes', 'is_correct' => false, 'sort_order' => 1],
            ['option_text' => 'wives', 'is_correct' => true, 'sort_order' => 2],
            ['option_text' => 'wive', 'is_correct' => false, 'sort_order' => 3],
        ]);

        $q3 = $assessment1->questions()->create([
            'question_text' => 'Fill in the blank: The news ________ at 6.30 p.m.',
            'question_type' => 'multiple_choice',
            'sort_order' => 3,
        ]);
        $q3->options()->createMany([
            ['option_text' => 'is', 'is_correct' => true, 'sort_order' => 1],
            ['option_text' => 'are', 'is_correct' => false, 'sort_order' => 2],
        ]);

        // Gerunds Quiz
        $assessment2 = Assessment::create([
            'level_id' => $level->id,
            'chapter_id' => $chapter2->id,
            'title' => 'Gerunds Quiz',
            'description' => 'Test your understanding of Gerunds.',
            'pass_percentage' => 70.00,
            'total_marks' => 10,
            'passing_marks' => 7,
            'duration_minutes' => 15,
            'is_mandatory' => true,
            'is_active' => true,
        ]);

        $gq1 = $assessment2->questions()->create([
            'question_text' => 'Identify the gerund in the sentence: "Swimming is my favourite sport."',
            'question_type' => 'multiple_choice',
            'sort_order' => 1,
        ]);
        $gq1->options()->createMany([
            ['option_text' => 'Swimming', 'is_correct' => true, 'sort_order' => 1],
            ['option_text' => 'favourite', 'is_correct' => false, 'sort_order' => 2],
            ['option_text' => 'sport', 'is_correct' => false, 'sort_order' => 3],
        ]);

        $gq2 = $assessment2->questions()->create([
            'question_text' => 'Choose the correct word: "My sister enjoys ________."',
            'question_type' => 'multiple_choice',
            'sort_order' => 2,
        ]);
        $gq2->options()->createMany([
            ['option_text' => 'Painting', 'is_correct' => true, 'sort_order' => 1],
            ['option_text' => 'Paint', 'is_correct' => false, 'sort_order' => 2],
        ]);

        $gq3 = $assessment2->questions()->create([
            'question_text' => 'Choose the correct form: "We are interested in ________ English."',
            'question_type' => 'multiple_choice',
            'sort_order' => 3,
        ]);
        $gq3->options()->createMany([
            ['option_text' => 'Learning', 'is_correct' => true, 'sort_order' => 1],
            ['option_text' => 'Learn', 'is_correct' => false, 'sort_order' => 2],
        ]);
    }
}
