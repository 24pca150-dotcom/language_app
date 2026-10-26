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
use App\Models\LearningMode;
use Illuminate\Support\Facades\DB;

class CurriculumMasterSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // -------------------------------------------------------------
        // 1. School (Tenant), Property, Package, and Learning Modes
        // -------------------------------------------------------------
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

        $property = Property::firstOrCreate(
            ['property_code' => 'PROP-SCH-001'],
            [
                'tenant_id' => $tenant->id,
                'property_name' => 'Ariga Public School Campus',
                'location' => 'Virtual/Online',
                'address' => 'Online Portal',
                'max_users' => 500,
                'is_active' => true,
            ]
        );

        $package = Package::firstOrCreate(
            ['code' => 'PKG-ENGLISH-BEGINNER'],
            [
                'name' => 'English for Beginner Package',
                'description' => 'Complete package containing all 4 English skill levels: Homophones, Sounds of Animals, Reading, and Writing.',
                'is_active' => true,
            ]
        );

        $learningModes = LearningMode::whereIn('code', ['BEGINNER', 'CHILDEREN'])->get();
        if ($learningModes->isEmpty()) {
            $learningModes = LearningMode::all();
        }
        $learningModeIds = $learningModes->pluck('id')->toArray();

        // -------------------------------------------------------------
        // 2. The Course (English for Beginner)
        // -------------------------------------------------------------
        $course = Course::updateOrCreate(
            ['name' => 'English for Beginner'],
            [
                'code' => 'CRS-ENG-001',
                'description' => 'Comprehensive 4-level English foundation: Homophones, Sounds of Animals & Birds, Reading Skills, and Writing & Grammar.',
                'no_of_levels' => 4,
                'is_active' => true,
            ]
        );

        // Map Property -> Package -> Course
        DB::table('property_packages')->updateOrInsert(
            [
                'property_id' => $property->id,
                'package_id' => $package->id,
            ],
            [
                'course_id' => $course->id,
                'learning_mode_ids' => json_encode($learningModeIds),
                'start_date' => now()->subDay()->format('Y-m-d'),
                'end_date' => now()->addYears(5)->format('Y-m-d'),
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]
        );

        // Clean out legacy mappings for this course so only the 4 levels remain active
        DB::table('course_package_levels')->where('course_id', $course->id)->delete();

        // =============================================================
        // LEVEL 1: HOMOPHONES
        // =============================================================
        $level1 = Level::updateOrCreate(
            ['code' => 'LVL-HOMOPHONES'],
            [
                'name' => 'Level 1 - Homophones',
                'description' => 'Listening Skills & Homophones: Words that sound the same but have different meanings and spellings.',
                'sort_order' => 1,
                'is_active' => true,
            ]
        );

        DB::table('course_package_levels')->insert([
            'course_id' => $course->id,
            'package_id' => $package->id,
            'level_id' => $level1->id,
            'is_mandatory' => true,
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $chapter1 = Chapter::updateOrCreate(
            ['code' => 'CHP-HOMOPHONES'],
            [
                'name' => 'Homophones',
                'description' => 'Learn homophones with audio examples, complete A to Z list, and practice exercises.',
                'sort_order' => 1,
                'is_active' => true,
            ]
        );

        DB::table('level_chapter')->updateOrInsert(
            ['level_id' => $level1->id, 'chapter_id' => $chapter1->id],
            ['sort_order' => 1, 'is_active' => true, 'created_at' => now(), 'updated_at' => now()]
        );

        // 126 Homophones Table
        $homophonesList = [
            ["Accept – Except", "Accept = receive; Except = leaving out"],
            ["Access – Excess", "Access = entry/use; Excess = too much"],
            ["Ad – Add", "Ad = advertisement; Add = join together"],
            ["Addition – Edition", "Addition = adding something; Edition = version of a book"],
            ["Affect – Effect", "Affect = influence; Effect = result"],
            ["Allowed – Aloud", "Allowed = permitted; Aloud = spoken loudly"],
            ["Ant – Aunt", "Ant = small insect; Aunt = parent’s sister"],
            ["Are – Our", "Are = form of ‘be’; Our = belonging to us"],
            ["Ate – Eight", "Ate = past tense of eat; Eight = number 8"],
            ["Be – Bee", "Be = exist; Bee = insect"],
            ["Bear – Bare", "Bear = animal; Bare = uncovered"],
            ["Berry – Bury", "Berry = small fruit; Bury = place underground"],
            ["Blew – Blue", "Blew = past tense of blow; Blue = colour"],
            ["Board – Bored", "Board = flat piece; Bored = not interested"],
            ["Break – Brake", "Break = separate into pieces; Brake = stops vehicle"],
            ["Buy – Bye – By", "Buy = purchase; Bye = farewell; By = near"],
            ["Capital – Capitol", "Capital = main city/money; Capitol = government building"],
            ["Ceiling – Sealing", "Ceiling = top inside roof; Sealing = closing tightly"],
            ["Celery – Salary", "Celery = vegetable; Salary = monthly pay"],
            ["Cell – Sell", "Cell = small room; Sell = give for money"],
            ["Cent – Scent – Sent", "Cent = coin; Scent = smell; Sent = sent away"],
            ["Cereal – Serial", "Cereal = breakfast food; Serial = arranged in order"],
            ["Chews – Choose", "Chews = bites food; Choose = select"],
            ["Clothes – Close", "Clothes = things we wear; Close = shut"],
            ["Conscience – Conscious", "Conscience = sense of right/wrong; Conscious = awake/aware"],
            ["Council – Counsel", "Council = group of people; Counsel = advice"],
            ["Course – Coarse", "Course = direction/study; Coarse = rough"],
            ["Creak – Creek", "Creak = squeaky sound; Creek = small stream"],
            ["Dear – Deer", "Dear = loved one; Deer = animal"],
            ["Desert – Dessert", "Desert = dry land; Dessert = sweet dish"],
            ["Dew – Do – Due", "Dew = water drops; Do = perform; Due = expected"],
            ["Die – Dye", "Die = stop living; Dye = colour"],
            ["Fair – Fare", "Fair = just/beautiful; Fare = travel fee"],
            ["Fir – Fur", "Fir = tree; Fur = animal hair"],
            ["Flew – Flu", "Flew = travelled by air; Flu = illness"],
            ["Flour – Flower", "Flour = cooking powder; Flower = blooming plant"],
            ["For – Four", "For = used to indicate purpose; Four = number 4"],
            ["Form – From", "Form = shape/type; From = indicating source"],
            ["Forth – Fourth", "Forth = forward; Fourth = position number 4"],
            ["Great – Grate", "Great = excellent; Grate = shred"],
            ["Groan – Grown", "Groan = sound of pain; Grown = matured"],
            ["Guessed – Guest", "Guessed = thought without certainty; Guest = visitor"],
            ["Hair – Hare", "Hair = strands on head; Hare = rabbit-like animal"],
            ["Hall – Haul", "Hall = large room; Haul = pull/carry"],
            ["Hay – Hey", "Hay = dry grass; Hey = greeting"],
            ["Heal – Heel", "Heal = make better; Heel = back part of foot"],
            ["Hear – Here", "Hear = listen; Here = this place"],
            ["Heard – Herd", "Heard = listened; Herd = group of animals"],
            ["Higher – Hire", "Higher = above; Hire = employ"],
            ["Hole – Whole", "Hole = opening; Whole = complete"],
            ["Horse – Hoarse", "Horse = animal; Hoarse = rough voice"],
            ["Hour – Our", "Hour = 60 minutes; Our = belonging to us"],
            ["I – Eye", "I = pronoun; Eye = body part"],
            ["Its – It’s", "Its = belonging to it; It’s = it is"],
            ["Lead – Led", "Lead = guide; Led = guided in past"],
            ["Loose – Lose", "Loose = not tight; Lose = unable to find"],
            ["Maid – Made", "Maid = helper; Made = created"],
            ["Mail – Male", "Mail = letters; Mail = boy/man"],
            ["Main – Mane", "Main = chief; Mane = lion’s hair"],
            ["Meat – Meet", "Meat = animal flesh; Meet = come together"],
            ["Missed – Mist", "Missed = failed to catch; Mist = fog"],
            ["New – Knew", "New = fresh; Knew = past tense of know"],
            ["Night – Knight", "Night = dark time; Knight = warrior"],
            ["No – Know", "No = negative answer; Know = understand"],
            ["None – Nun", "None = nothing; Nun = religious woman"],
            ["Nose – Knows", "Nose = body part; Knows = understands"],
            ["Not – Knot", "Not = negative word; Knot = tied loop"],
            ["Off – Of", "Off = away from; Of = showing relation"],
            ["Oh – Owe", "Oh = expression; Owe = have to pay"],
            ["One – Won", "One = number 1; Won = past tense of win"],
            ["Pail – Pale", "Pail = bucket; Pale = light colour"],
            ["Pain – Pane", "Pain = suffering; Pane = sheet of glass"],
            ["Pair – Pare – Pear", "Pair = set of two; Pare = trim; Pear = fruit"],
            ["Passed – Past", "Passed = moved ahead; Past = earlier time"],
            ["Patience – Patients", "Patience = calm waiting; Patients = sick people"],
            ["Pause – Paws", "Pause = short stop; Paws = animal feet"],
            ["Peace – Piece", "Peace = calmness; Piece = part"],
            ["Peak – Peek", "Peak = top point; Peek = quick look"],
            ["Peal – Peel", "Peal = loud ringing sound; Peel = remove skin"],
            ["Plain – Plane", "Plain = simple; Plane = aircraft"],
            ["Principal – Principle", "Principal = head of school; Principle = rule"],
            ["Profit – Prophet", "Profit = gain; Prophet = person who predicts"],
            ["Quiet – Quite", "Quiet = silent; Quite = very"],
            ["Rain – Reign", "Rain = water from clouds; Reign = rule"],
            ["Raise – Rays", "Raise = lift up; Rays = beams of light"],
            ["Rap – Wrap", "Rap = hit/talk rhythmically; Wrap = cover"],
            ["Read – Red", "Read = look at words; Red = colour"],
            ["Reads – Reeds", "Reads = looks at words; Reeds = tall grass plants"],
            ["Real – Reel", "Real = true; Reel = roll/spool"],
            ["Right – Write", "Right = correct; Write = form words"],
            ["Ring – Wring", "Ring = circular object; Wring = twist tightly"],
            ["Road – Rode", "Road = path; Rode = past tense of ride"],
            ["Sail – Sale", "Sail = move by boat; Sale = selling"],
            ["Scene – Seen", "Scene = part of play/movie; Seen = viewed"],
            ["Sea – See", "Sea = large water body; See = look"],
            ["Seam – Seem", "Seam = line joining cloth; Seem = appear"],
            ["Sense – Since", "Sense = understanding; Since = from a time"],
            ["Sew – So – Sow", "Sew = stitch; So = therefore; Sow = plant seeds"],
            ["Soar – Sore", "Soar = fly high; Sore = painful"],
            ["Some – Sum", "Some = a few; Sum = total"],
            ["Son – Sun", "Son = boy child; Sun = star"],
            ["Stairs – Stares", "Stairs = steps; Stares = looks fixedly"],
            ["Stationary – Stationery", "Stationary = not moving; Stationery = writing materials"],
            ["Steak – Stake", "Steak = meat slice; Stake = wooden post"],
            ["Steal – Steel", "Steal = take secretly; Steel = strong metal"],
            ["Tacks – Tax", "Tacks = small nails; Tax = government charge"],
            ["Tail – Tale", "Tail = animal part; Tale = story"],
            ["Then – Than", "Then = at that time; Than = comparison word"],
            ["There – Their", "There = place; Their = belonging to them"],
            ["There – They’re – Their", "There = place; They’re = they are; Their = belonging to them"],
            ["Threw – Through", "Threw = tossed; Through = from one side to another"],
            ["To – Too – Two", "To = direction word; Too = also; Two = number 2"],
            ["Toad – Towed", "Toad = amphibian; Towed = pulled along"],
            ["Toes – Tows", "Toes = foot fingers; Tows = pulls along"],
            ["Wade – Weighed", "Wade = walk through water; Weighed = measured heaviness"],
            ["Waist – Waste", "Waist = middle body part; Waste = useless material"],
            ["Wait – Weight", "Wait = stay; Weight = heaviness"],
            ["Way – Weigh", "Way = path; Weigh = measure heaviness"],
            ["Weak – Week", "Weak = not strong; Week = seven days"],
            ["Weather – Whether", "Weather = climate; Whether = expressing choice"],
            ["Were – We’re", "Were = past form of are; We’re = we are"],
            ["Where – Were", "Where = asks place; Were = past form of are"],
            ["Which – Witch", "Which = asking choice; Witch = magical woman"],
            ["Whose – Who’s", "Whose = belonging to whom; Who’s = who is"],
            ["Wood – Would", "Wood = material from trees; Would = modal verb"],
            ["Your – You’re", "Your = belonging to you; You’re = you are"],
        ];

        $homophonesTableContent = [["S.No", "Homophones", "Meaning"]];
        foreach ($homophonesList as $idx => $hp) {
            $homophonesTableContent[] = [(string)($idx + 1), $hp[0], $hp[1]];
        }

        // Content 1: Intro to Homophones
        $h1Blocks = [
            ["type" => "header", "data" => ["text" => "Level 1: Basic Listening Skills 🎧", "level" => 2]],
            ["type" => "paragraph", "data" => ["text" => "Hai Kids ! Welcome to the world of fun listening activities! Let us begin our exciting learning journey by developing one of the most important language skills — Listening."]],
            ["type" => "paragraph", "data" => ["text" => "⮚ Listening is the first step in learning any language. Before we speak, read, or write, we first learn by listening carefully to the sounds, words, and sentences around us. Good listening helps us follow instructions, speak clearly, learn new words, and communicate confidently in English."]],
            ["type" => "paragraph", "data" => ["text" => "⮚ Have you ever listened to the chirping of birds, the barking of dogs, or words that sound the same but have different meanings? In this module, you will explore many such interesting sounds and words through fun audio and video activities.<br><br><strong>Let us listen, learn, and enjoy together!</strong>"]],
            ["type" => "header", "data" => ["text" => "What are Homophones?", "level" => 3]],
            ["type" => "paragraph", "data" => ["text" => "Have you ever heard two words that sound exactly the same but have different meanings and spellings? Those words are called <strong>Homophones</strong>. Homophones are words that sound the same but have different meanings and different spellings.<br><br>• <strong>HOMO</strong> means <em>same</em><br>• <strong>PHONE</strong> means <em>sound</em><br><br>So, when we put them together, <strong>Homophones</strong> means words that have the same sound. Remember, even though they sound alike, their meanings and spellings are different."]],
            ["type" => "header", "data" => ["text" => "For example, children, listen carefully:", "level" => 3]],
            ["type" => "paragraph", "data" => ["text" => "• <strong>I can see the blue sea from my window.</strong><br>Here, <em>sea</em> means the large water body, and <em>see</em> means to look. Both words sound the same, but their meanings are different."]],
            ["type" => "paragraph", "data" => ["text" => "• <strong>The sun is bright, and my son is playing outside.</strong><br><em>Sun</em> is the shining star in the sky, while <em>son</em> means a boy child."]],
            ["type" => "paragraph", "data" => ["text" => "• <strong>I will write my name on the right side of the page.</strong><br><em>Write</em> means to form words, and <em>right</em> means correct or a direction."]],
            ["type" => "paragraph", "data" => ["text" => "Isn’t it interesting? Homophones make English fun and exciting to learn. So, let’s listen carefully, learn new words, and enjoy the wonderful world of homophones!"]],
            ["type" => "header", "data" => ["text" => "Audio Sentence Examples 💡", "level" => 3]],
            ["type" => "paragraph", "data" => ["text" => "Listen carefully to the audio sentence and choose the correct word from the brackets."]],
        ];

        // 6 Audio Sentence Examples
        $sampleExamples = [
            ["My friends said bye before leaving the classroom.", "My friends said ______ before leaving the classroom.", ["bye", "buy", "by"], "bye"],
            ["We saw a colourful flower blooming near the gate.", "We saw a colourful ______ blooming near the gate.", ["flower", "flour"], "flower"],
            ["I can hear music coming from the next room.", "I can ______ music coming from the next room.", ["hear", "here"], "hear"],
            ["My sister will write a poem for the competition.", "My sister will ______ a poem for the competition.", ["write", "right"], "write"],
            ["The children waited for an hour before the show began.", "The children waited for an ______ before the show began.", ["hour", "our"], "hour"],
            ["The bright sun disappeared behind the clouds.", "The bright ______ disappeared behind the clouds.", ["sun", "son"], "sun"],
        ];

        foreach ($sampleExamples as $sIdx => $se) {
            $opts = [];
            foreach ($se[2] as $oId => $optText) {
                $opts[] = [
                    'id' => $oId + 1,
                    'text' => $optText,
                    'is_correct' => ($optText === $se[3]),
                ];
            }
            $act = Activity::updateOrCreate(
                ['title' => "Homophones Example " . ($sIdx + 1), 'tenant_id' => null],
                [
                    'type' => 'mcq',
                    'data_json' => [
                        'question' => $se[1] . " (" . implode(' / ', $se[2]) . ")",
                        'options' => $opts,
                        'explanation' => "Full sentence: " . $se[0],
                    ],
                    'created_by' => null,
                ]
            );
            $h1Blocks[] = [
                'type' => 'activity',
                'data' => [
                    'type' => 'activity_reference',
                    'activityReferenceId' => $act->id,
                ],
            ];
        }

        // Content 2: A to Z List + 26 Exercises
        $h2Blocks = [
            ["type" => "header", "data" => ["text" => "Let’s have a Look at the List of Homophones from A to Z! 📚", "level" => 2]],
            [
                "type" => "table",
                "data" => [
                    "withHeadings" => true,
                    "content" => $homophonesTableContent,
                ],
            ],
            ["type" => "header", "data" => ["text" => "Now, let us begin the exercises 🎯", "level" => 2]],
            ["type" => "paragraph", "data" => ["text" => "Listen carefully to the audio sentence and choose the correct word from the brackets:"]],
        ];

        $exercise26 = [
            ["Please accept my gift.", "Please ______ my gift.", ["accept", "except"], "accept"],
            ["We can access the library online.", "We can ______ the library online.", ["access", "excess"], "access"],
            ["I saw an ad in the newspaper.", "I saw an ______ in the newspaper.", ["ad", "add"], "ad"],
            ["This is the latest edition of the book.", "This is the latest ______ of the book.", ["addition", "edition"], "edition"],
            ["Loud noise can affect sleep.", "Loud noise can ______ sleep.", ["affect", "effect"], "affect"],
            ["Students are allowed to play outside.", "Students are ______ to play outside.", ["allowed", "aloud"], "allowed"],
            ["My aunt visited us yesterday.", "My ______ visited us yesterday.", ["ant", "aunt"], "aunt"],
            ["Our school is very big.", "______ school is very big.", ["are", "our"], "our"],
            ["She ate two apples.", "She ______ two apples.", ["ate", "eight"], "ate"],
            ["A bee is sitting on the flower.", "A ______ is sitting on the flower.", ["be", "bee"], "bee"],
            ["The bear lives in the forest.", "The ______ lives in the forest.", ["bear", "bare"], "bear"],
            ["They bury the treasure underground.", "They ______ the treasure underground.", ["berry", "bury"], "bury"],
            ["The wind blew strongly last night.", "The wind ______ strongly last night.", ["blew", "blue"], "blew"],
            ["I was bored during the long speech.", "I was ______ during the long speech.", ["board", "bored"], "bored"],
            ["Use the brake before the turn.", "Use the ______ before the turn.", ["break", "brake"], "brake"],
            ["I will buy a new bag today.", "I will ______ a new bag today.", ["buy", "bye", "by"], "buy"],
            ["Chennai is the capital of Tamil Nadu.", "Chennai is the ______ of Tamil Nadu.", ["capital", "capitol"], "capital"],
            ["The ceiling fan is new.", "The ______ fan is new.", ["ceiling", "sealing"], "ceiling"],
            ["My father receives his salary every month.", "My father receives his ______ every month.", ["celery", "salary"], "salary"],
            ["They sell fruits in the market.", "They ______ fruits in the market.", ["cell", "sell"], "sell"],
            ["She sent me a birthday card.", "She ______ me a birthday card.", ["cent", "scent", "sent"], "sent"],
            ["I eat cereal every morning.", "I eat ______ every morning.", ["cereal", "serial"], "cereal"],
            ["Please choose your favourite colour.", "Please ______ your favourite colour.", ["chews", "choose"], "choose"],
            ["Fold your clothes neatly.", "Fold your ______ neatly.", ["clothes", "close"], "clothes"],
            ["He was conscious after the accident.", "He was ______ after the accident.", ["conscience", "conscious"], "conscious"],
            ["The council met to discuss the problem.", "The ______ met to discuss the problem.", ["council", "counsel"], "council"],
        ];

        foreach ($exercise26 as $eIdx => $ex) {
            $opts = [];
            foreach ($ex[2] as $oId => $optText) {
                $opts[] = [
                    'id' => $oId + 1,
                    'text' => $optText,
                    'is_correct' => (strtolower($optText) === strtolower($ex[3])),
                ];
            }
            $act = Activity::updateOrCreate(
                ['title' => "Homophones Exercise " . ($eIdx + 1), 'tenant_id' => null],
                [
                    'type' => 'mcq',
                    'data_json' => [
                        'question' => $ex[1] . " (" . implode(' / ', $ex[2]) . ")",
                        'options' => $opts,
                        'explanation' => "Sentence: " . $ex[0],
                    ],
                    'created_by' => null,
                ]
            );
            $h2Blocks[] = [
                'type' => 'activity',
                'data' => [
                    'type' => 'activity_reference',
                    'activityReferenceId' => $act->id,
                ],
            ];
        }

        $h2Blocks[] = ["type" => "header", "data" => ["text" => "Fantastic work, kids! 🌟", "level" => 2]];
        $h2Blocks[] = ["type" => "paragraph", "data" => ["text" => "You learned many interesting homophones through fun listening practice. By listening carefully and choosing the correct words, you are becoming smart and confident English learners. Keep practicing and enjoy learning new words every day."]];

        // Create Content 1 & 2 for Chapter 1
        DB::table('content_chapters')->where('chapter_id', $chapter1->id)->delete();

        $c1_1 = Content::updateOrCreate(
            ['name' => 'Homophones - Concept & Examples'],
            [
                'title' => 'Listening Skills & Introduction to Homophones',
                'sort_order' => 1,
                'is_active' => true,
                'text_content' => json_encode(['time' => time(), 'blocks' => $h1Blocks, 'version' => '2.29.1'], JSON_UNESCAPED_UNICODE),
            ]
        );

        $c1_2 = Content::updateOrCreate(
            ['name' => 'Homophones - A to Z & Practice'],
            [
                'title' => 'Homophones A to Z Directory & Exercises',
                'sort_order' => 2,
                'is_active' => true,
                'text_content' => json_encode(['time' => time(), 'blocks' => $h2Blocks, 'version' => '2.29.1'], JSON_UNESCAPED_UNICODE),
            ]
        );

        DB::table('content_chapters')->insert([
            ['content_id' => $c1_1->id, 'chapter_id' => $chapter1->id, 'sort_order' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['content_id' => $c1_2->id, 'chapter_id' => $chapter1->id, 'sort_order' => 2, 'created_at' => now(), 'updated_at' => now()],
        ]);


        // =============================================================
        // LEVEL 2: SOUNDS OF ANIMALS
        // =============================================================
        $level2 = Level::updateOrCreate(
            ['code' => 'LVL-ANIMAL-SOUNDS'],
            [
                'name' => 'Level 2 - Sounds of Animals & Birds',
                'description' => 'Explore the wonderful world of animal and bird sounds: Pierre Schaeffer quotes, 111 animal sounds directory, and listening games.',
                'sort_order' => 2,
                'is_active' => true,
            ]
        );

        DB::table('course_package_levels')->insert([
            'course_id' => $course->id,
            'package_id' => $package->id,
            'level_id' => $level2->id,
            'is_mandatory' => true,
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $chapter2 = Chapter::updateOrCreate(
            ['code' => 'CHP-ANIMAL-SOUNDS'],
            [
                'name' => 'Sounds of Animals & Birds',
                'description' => 'Listen and identify the sounds of 111 animals and birds.',
                'sort_order' => 1,
                'is_active' => true,
            ]
        );

        DB::table('level_chapter')->updateOrInsert(
            ['level_id' => $level2->id, 'chapter_id' => $chapter2->id],
            ['sort_order' => 1, 'is_active' => true, 'created_at' => now(), 'updated_at' => now()]
        );

        // 111 Animals & Sounds
        $animals111 = [
            ["Alligators", "hiss, grunt, roar"],
            ["Apes", "Gibber"],
            ["Badgers", "Growl"],
            ["Basenji dogs", "Yodel"],
            ["Bats", "Screech"],
            ["Bears", "Growl"],
            ["Bees", "hum, buzz"],
            ["Beetles", "Drone"],
            ["Birds", "chirp, twitter, tweet"],
            ["Bitterns", "Boom"],
            ["Blackbirds", "Whistle"],
            ["Calves", "Bleat"],
            ["Camels", "Grunt"],
            ["Cats", "mew, purr, meow, hiss, yowl"],
            ["Cattle", "moo, low, bawl, bellow"],
            ["Chicks", "Cheep"],
            ["Chickens", "Cluck"],
            ["Chinchillas", "Squeak"],
            ["Cicadas", "Sing"],
            ["Cocks", "Crow"],
            ["Cows", "low, moo"],
            ["Coyotes", "yelp, cry"],
            ["Crickets", "chirp, creak"],
            ["Crows", "Caw"],
            ["Cuckoos", "coo, cuckoo"],
            ["Curlews", "Pipe"],
            ["Deers", "Bell"],
            ["Dingos", "bark, cry"],
            ["Dodos", "squawk, cry"],
            ["Dogs", "bark, woof, arf"],
            ["Dolphins", "Click"],
            ["Donkeys", "Bray"],
            ["Doves", "Coo"],
            ["Ducks", "Quack"],
            ["Eagles", "Scream"],
            ["Elephants", "trumpet, roar"],
            ["Falcons", "Chant"],
            ["Ferrets", "Dook"],
            ["Flies", "buzz, hum"],
            ["Foxes", "bark, yelp, simper"],
            ["Frogs", "Croak"],
            ["Giraffes", "Bleat"],
            ["Goats", "Bleat"],
            ["Geese", "cackle, gobble, hiss, honk, quack"],
            ["Grasshoppers", "Chirp"],
            ["Guinea pigs", "Squeak"],
            ["Hamsters", "Squeak"],
            ["Hares", "Squeak"],
            ["Hens", "cackle, cluck"],
            ["Hermit Crab", "Chirp"],
            ["Hippopotamuses", "bellow, rumble, roar, growl"],
            ["Humans", "cry, scream, sing, talk"],
            ["Hogs", "Grunt"],
            ["Horses", "neigh, snort, whinny, nicker"],
            ["Hyenas", "laugh, scream"],
            ["Jackals", "Howl"],
            ["Jays", "Chatter"],
            ["Kangaroos", "Chortle"],
            ["Koalas", "scream, bellow, wail"],
            ["Komodo dragons", "growl, snarl, hiss"],
            ["Lambs", "Bleat"],
            ["Larks", "sing, warble"],
            ["Linnets", "Chuckle"],
            ["Lions", "roar, growl"],
            ["Llamas", "Growl"],
            ["Magpies", "Chatter"],
            ["Mice", "squeak, squeal"],
            ["Monkeys", "chatter, gibber, whoop"],
            ["Moose", "Bellow"],
            ["Mosquitoes", "Whine"],
            ["Narwhal", "Squeal"],
            ["Nightingales", "pipe, sing, warble"],
            ["Okapis", "cough, bellow"],
            ["Ostriches", "Chirp"],
            ["Owls", "hoot, scream, screech, shriek"],
            ["Oxen", "bellow, low"],
            ["Parrots", "talk, screech, squawk"],
            ["Peacocks", "Scream"],
            ["Peafowls", "Scream"],
            ["Pigs", "snort, grunt, squeal, oink"],
            ["Pigeons", "Coo"],
            ["Porpoises", "whistle, click"],
            ["Prairie dogs", "Bark"],
            ["Puffins", "Moo"],
            ["Queleas", "Chatter"],
            ["Rabbits", "squeak, drum"],
            ["Raccoons", "Chitter"],
            ["Rats", "Squeak"],
            ["Ravens", "Croak"],
            ["Rhinoceroses", "Bellow"],
            ["Robins", "Chirp"],
            ["Rooks", "Caw"],
            ["Rooster", "Crow"],
            ["Seagulls", "Scream"],
            ["Seals", "Bark"],
            ["Sheep", "Bleat"],
            ["Snakes", "Hiss"],
            ["Sparrows", "chirp, twitter"],
            ["Squirrels", "Squeak"],
            ["Stags", "Bellow"],
            ["Swallows", "twitter, squeal"],
            ["Swans", "Cry"],
            ["Tigers", "growl, roar"],
            ["Thrushes", "whistle, sing"],
            ["Turkeys", "Gobble"],
            ["Vultures", "Scream"],
            ["Walruses", "Groan"],
            ["Whales", "Sing"],
            ["Wolves", "howl, cry, yell"],
            ["Wrens", "Warble"],
            ["Zebras", "Whinny"],
        ];

        $animalTableContent = [["S.No", "Animal / Bird", "Sound"]];
        foreach ($animals111 as $aIdx => $an) {
            $animalTableContent[] = [(string)($aIdx + 1), $an[0], $an[1]];
        }

        $a1Blocks = [
            ["type" => "header", "data" => ["text" => "Welcome to the Sound Adventure! 🐾", "level" => 2]],
            ["type" => "paragraph", "data" => ["text" => "Hello little listeners! Are you ready for a fun sound adventure today?<br><br>Welcome to the wonderful world of animal and bird sounds! Have you ever heard a dog bark, a cat meow, or birds chirping in the morning? Every sound around us tells a story. Listening carefully helps us learn, understand, and enjoy the beautiful sounds of nature."]],
            ["type" => "paragraph", "data" => ["text" => "Animals and birds use different sounds to talk to one another, just like we use words. Some sounds warn others of danger, some show happiness, and some help them call their friends and family. In this video segment, we will listen, learn, and have fun identifying different sounds made by animals and birds. So, put on your listening ears and get ready for an exciting sound adventure! 🎶🐶🦜"]],
            ["type" => "header", "data" => ["text" => "Sounds of Animals & Birds", "level" => 3]],
            ["type" => "paragraph", "data" => ["text" => "<em>“Sound is the vocabulary of Nature.”</em><br>— <strong>Pierre Schaeffer</strong>"]],
            ["type" => "header", "data" => ["text" => "What is sound?", "level" => 3]],
            ["type" => "paragraph", "data" => ["text" => "Sound is a form of energy that we can hear. It is made when something vibrates or moves quickly. We hear many different sounds around us every day. For example, people talking, birds chirping, rain falling, music playing, and animals making sounds. Sound is very important because it helps us communicate, learn new things, and understand the world around us.<br><br>Animals and birds use sounds to communicate in their daily life. Just like we use words to talk, animals and birds also use sounds to share messages. By listening carefully to these sounds, we can learn more about their feelings and actions!"]],
            ["type" => "header", "data" => ["text" => "Directory of Animal & Bird Sounds (111 Species) 🦁🦜", "level" => 2]],
            [
                "type" => "table",
                "data" => [
                    "withHeadings" => true,
                    "content" => $animalTableContent,
                ],
            ],
        ];

        // Content 2: Animal Activities
        $a2Blocks = [
            ["type" => "header", "data" => ["text" => "Activity 1 – Listen and Identify the Sound 🔊", "level" => 2]],
            ["type" => "paragraph", "data" => ["text" => "Now let us test our listening skills. Let’s see if you can identify the correct sound!"]],
        ];

        $act1Items = [
            ["The baby chick began to ________ near its mother.", ["cheep", "roar"], "cheep"],
            ["In the jungle, the tiger started to ________ loudly.", ["quack", "growl"], "growl"],
            ["The donkey on the farm gave a loud ________.", ["bray", "chirp"], "bray"],
            ["The snake hiding under the rock began to ________.", ["hiss", "moo"], "hiss"],
            ["The little sparrow outside the window started to ________.", ["neigh", "chirp"], "chirp"],
            ["The frog near the pond could be heard ________.", ["croaking", "barking"], "croaking"],
            ["The elephant at the zoo gave a loud ________.", ["squeak", "trumpet"], "trumpet"],
            ["The sheep in the meadow began to ________.", ["bleat", "crow"], "bleat"],
            ["The horse happily started to ________ as it ran.", ["whinny", "buzz"], "whinny"],
            ["The rooster on the farm began to ________ early in the morning.", ["crow", "hiss"], "crow"],
        ];

        foreach ($act1Items as $aiIdx => $ai) {
            $opts = [];
            foreach ($ai[1] as $oIdx => $optText) {
                $opts[] = [
                    'id' => $oIdx + 1,
                    'text' => $optText,
                    'is_correct' => ($optText === $ai[2]),
                ];
            }
            $act = Activity::updateOrCreate(
                ['title' => "Animal Sound Activity 1 - Question " . ($aiIdx + 1), 'tenant_id' => null],
                [
                    'type' => 'mcq',
                    'data_json' => [
                        'question' => $ai[0] . " (" . implode(' / ', $ai[1]) . ")",
                        'options' => $opts,
                    ],
                    'created_by' => null,
                ]
            );
            $a2Blocks[] = [
                'type' => 'activity',
                'data' => [
                    'type' => 'activity_reference',
                    'activityReferenceId' => $act->id,
                ],
            ];
        }

        $a2Blocks[] = ["type" => "header", "data" => ["text" => "Listen Carefully to the Audio Clip & Choose the Answer 🎧", "level" => 2]];

        $clipExercises = [
            ["The little puppy in the garden ________.", ["barks", "moos"], "barks"],
            ["The hungry kitten began to ________ loudly.", ["meow", "roar"], "meow"],
            ["The farmer heard the cow ________ in the shed.", ["quack", "moo"], "moo"],
            ["The duck near the pond started to ________.", ["quack", "neigh"], "quack"],
            ["The lion in the forest gave a loud ________.", ["chirp", "roar"], "roar"],
            ["At night, the owl can be heard ________.", ["hooting", "buzzing"], "hooting"],
            ["The horse in the field began to ________.", ["hiss", "neigh"], "neigh"],
            ["The bee around the flowers made a ________ sound.", ["buzz", "growl"], "buzz"],
            ["The goat on the farm started to ________.", ["crow", "bleat"], "bleat"],
            ["Early in the morning, the crow began to ________.", ["caw", "trumpet"], "caw"],
        ];

        foreach ($clipExercises as $ceIdx => $ce) {
            $opts = [];
            foreach ($ce[1] as $oIdx => $optText) {
                $opts[] = [
                    'id' => $oIdx + 1,
                    'text' => $optText,
                    'is_correct' => ($optText === $ce[2]),
                ];
            }
            $act = Activity::updateOrCreate(
                ['title' => "Animal Sound Clip Exercise " . ($ceIdx + 1), 'tenant_id' => null],
                [
                    'type' => 'mcq',
                    'data_json' => [
                        'question' => $ce[0] . " (" . implode(' / ', $ce[1]) . ")",
                        'options' => $opts,
                    ],
                    'created_by' => null,
                ]
            );
            $a2Blocks[] = [
                'type' => 'activity',
                'data' => [
                    'type' => 'activity_reference',
                    'activityReferenceId' => $act->id,
                ],
            ];
        }

        $a2Blocks[] = ["type" => "header", "data" => ["text" => "Activity 2 – Listen and Tick the Correct Animal / Bird 🎉", "level" => 2]];
        $a2Blocks[] = ["type" => "paragraph", "data" => ["text" => "This time, you will hear a sound and choose the correct animal or bird. Listen carefully and tick the right answer! ✔️"]];

        $act2SampleAndEx = [
            ["Which animal makes the sound “Oink”?", ["Horse", "Pig"], "Pig"],
            ["Which bird makes the sound “Tweet”?", ["Sparrow", "Duck"], "Sparrow"],
            ["Which animal makes the sound “Croak”?", ["Cat", "Frog"], "Frog"],
            ["Which animal makes the sound “Bray”?", ["Donkey", "Cow"], "Donkey"],
            ["Which bird makes the sound “Crow”?", ["Rooster", "Owl"], "Rooster"],
            ["Which insect makes the sound “Hum”?", ["Tiger", "Bee"], "Bee"],
            ["Which animal makes the sound “Howl”?", ["Goat", "Wolf"], "Wolf"],
            ["Which bird makes the sound “Coo”?", ["Pigeon", "Crow"], "Pigeon"],
            ["Which animal makes the sound “Trumpet”?", ["Dog", "Elephant"], "Elephant"],
            ["Which animal makes the sound “Squeak”?", ["Mouse", "Lion"], "Mouse"],
            // Exercise 10
            ["Which animal makes the sound “Meow”?", ["Dog", "Cat"], "Cat"],
            ["Which bird makes the sound “Quack”?", ["Duck", "Owl"], "Duck"],
            ["Which animal makes the sound “Roar”?", ["Lion", "Goat"], "Lion"],
            ["Which insect makes the sound “Buzz”?", ["Crow", "Bee"], "Bee"],
            ["Which animal makes the sound “Neigh”?", ["Cow", "Horse"], "Horse"],
            ["Which bird makes the sound “Hoot”?", ["Owl", "Sparrow"], "Owl"],
            ["Which animal makes the sound “Bleat”?", ["Tiger", "Goat"], "Goat"],
            ["Which bird makes the sound “Caw”?", ["Crow", "Peacock"], "Crow"],
            ["Which animal makes the sound “Moo”?", ["Dog", "Cow"], "Cow"],
            ["Which animal makes the sound “Hiss”?", ["Duck", "Snake"], "Snake"],
        ];

        foreach ($act2SampleAndEx as $a2Idx => $a2) {
            $opts = [];
            foreach ($a2[1] as $oIdx => $optText) {
                $opts[] = [
                    'id' => $oIdx + 1,
                    'text' => $optText,
                    'is_correct' => ($optText === $a2[2]),
                ];
            }
            $act = Activity::updateOrCreate(
                ['title' => "Animal Match Challenge " . ($a2Idx + 1), 'tenant_id' => null],
                [
                    'type' => 'mcq',
                    'data_json' => [
                        'question' => $a2[0] . " (" . implode(' / ', $a2[1]) . ")",
                        'options' => $opts,
                    ],
                    'created_by' => null,
                ]
            );
            $a2Blocks[] = [
                'type' => 'activity',
                'data' => [
                    'type' => 'activity_reference',
                    'activityReferenceId' => $act->id,
                ],
            ];
        }

        $a2Blocks[] = ["type" => "header", "data" => ["text" => "Wonderful job, little listeners! 👏🎉", "level" => 2]];
        $a2Blocks[] = ["type" => "paragraph", "data" => ["text" => "Today, we learned that every animal and bird has its own special sound. By listening carefully, we can recognize and understand the amazing voices of nature around us.<br><br><strong>“Good listeners are good learners.” 🌟</strong><br>Keep listening, keep learning, and keep enjoying the beautiful sounds of the world around you!"]];

        DB::table('content_chapters')->where('chapter_id', $chapter2->id)->delete();

        $c2_1 = Content::updateOrCreate(
            ['name' => 'Animal Sounds - Vocabulary of Nature'],
            [
                'title' => 'Sounds of Animals & Birds - 111 Species Directory',
                'sort_order' => 1,
                'is_active' => true,
                'text_content' => json_encode(['time' => time(), 'blocks' => $a1Blocks, 'version' => '2.29.1'], JSON_UNESCAPED_UNICODE),
            ]
        );

        $c2_2 = Content::updateOrCreate(
            ['name' => 'Animal Sounds - Practice & Challenges'],
            [
                'title' => 'Animal Sounds Listening Activities & Identification',
                'sort_order' => 2,
                'is_active' => true,
                'text_content' => json_encode(['time' => time(), 'blocks' => $a2Blocks, 'version' => '2.29.1'], JSON_UNESCAPED_UNICODE),
            ]
        );

        DB::table('content_chapters')->insert([
            ['content_id' => $c2_1->id, 'chapter_id' => $chapter2->id, 'sort_order' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['content_id' => $c2_2->id, 'chapter_id' => $chapter2->id, 'sort_order' => 2, 'created_at' => now(), 'updated_at' => now()],
        ]);


        // =============================================================
        // LEVEL 3: READING
        // =============================================================
        $level3 = Level::updateOrCreate(
            ['code' => 'LVL-READING-SKILLS'],
            [
                'name' => 'Level 3 - Reading Skills',
                'description' => 'English Alphabet, Vowels, Consonants, Letter Counting, Jumbled Words, and Compound Words.',
                'sort_order' => 3,
                'is_active' => true,
            ]
        );

        DB::table('course_package_levels')->insert([
            'course_id' => $course->id,
            'package_id' => $package->id,
            'level_id' => $level3->id,
            'is_mandatory' => true,
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $chapter3 = Chapter::updateOrCreate(
            ['code' => 'CHP-READING-BASICS'],
            [
                'name' => 'Reading Skills & Compound Words',
                'description' => 'Letters, vowels, consonants, letter count, word puzzles, and compound words.',
                'sort_order' => 1,
                'is_active' => true,
            ]
        );

        DB::table('level_chapter')->updateOrInsert(
            ['level_id' => $level3->id, 'chapter_id' => $chapter3->id],
            ['sort_order' => 1, 'is_active' => true, 'created_at' => now(), 'updated_at' => now()]
        );

        $r1Blocks = [
            ["type" => "header", "data" => ["text" => "Level 3: Reading Skills 📖", "level" => 2]],
            ["type" => "paragraph", "data" => ["text" => "Reading is the ability to recognize letters, words, and sentences and understand their meaning. It is an essential language skill that helps learners acquire knowledge, improve vocabulary, and develop communication skills. Reading begins with identifying letters and sounds and gradually progresses to understanding words, phrases, and complete texts."]],
            ["type" => "header", "data" => ["text" => "ENGLISH ALPHABETS", "level" => 3]],
            ["type" => "paragraph", "data" => ["text" => "The English alphabet consists of 26 letters, which are the building blocks of all English words. Each letter has an uppercase (capital) and lowercase (small) form."]],
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
            ["type" => "header", "data" => ["text" => "VOWELS", "level" => 3]],
            ["type" => "paragraph", "data" => ["text" => "• The English language has five vowels: <strong>A, E, I, O, U</strong><br>• It helps produce speech sounds with an open mouth and without blocking the flow of air.<br>• For example, when we pronounce the letter “e”, only the mouth opens but our lips, tongue, and teeth do not move.<br><br><strong>Eg: Identify the Vowels in these words:</strong><br>• The vowel in the word <em>Fish</em> is “i”.<br>• The vowel in the word <em>Eyes</em> is “e”.<br>• The vowels in the word <em>Apple</em> are “a”, “e”.<br>• The vowels in the word <em>Blue</em> are “u”, “e”.<br>• The vowels in the word <em>Ice</em> are “i”, “e”."]],
            ["type" => "header", "data" => ["text" => "CONSONANTS", "level" => 3]],
            ["type" => "paragraph", "data" => ["text" => "• There are 21 consonants in the English language: <strong>B, C, D, F, G, H, J, K, L, M, N, P, Q, R, S, T, V, W, X, Y, Z</strong><br>• Consonant sounds are produced when the flow of air is partly or completely blocked by the lips, teeth, or tongue.<br>• For instance, when we pronounce the letter “l”, we have to move our tongue to touch our palate.<br><br><strong>Eg: Find the consonants in the following words:</strong><br>• Sitting: “s”, “t”, “n”, “g”<br>• Stopped: “s”, “t”, “p”, “d”<br>• Drop: “d”, “r”, “p”<br>• Plan: “p”, “l”, “n”<br>• Kid: “k”, “d”."]],
            ["type" => "header", "data" => ["text" => "Task 1: Count the letters! 🔢", "level" => 3]],
            ["type" => "paragraph", "data" => ["text" => "Read the given word carefully and count the number of letters in the word."]],
        ];

        // Task 1: 20 words count
        $countWords20 = [
            ["On", 2], ["Cat", 3], ["Book", 4], ["Apple", 5], ["Garden", 6],
            ["Teacher", 7], ["Elephant", 8], ["Notebook", 8], ["Backpack", 8], ["Sunflower", 9],
            ["Classroom", 9], ["Footballer", 10], ["Strawberry", 10], ["Playground", 10], ["Basketball", 10],
            ["Friendship", 10], ["Understand", 10], ["Environment", 11], ["Mathematics", 11], ["Communication", 13]
        ];

        foreach ($countWords20 as $cwIdx => $cw) {
            $act = Activity::updateOrCreate(
                ['title' => "Reading Task 1 - Letter Count " . ($cwIdx + 1), 'tenant_id' => null],
                [
                    'type' => 'mcq',
                    'data_json' => [
                        'question' => "How many letters are in the word \"{$cw[0]}\"?",
                        'options' => [
                            ['id' => 1, 'text' => (string)$cw[1], 'is_correct' => true],
                            ['id' => 2, 'text' => (string)($cw[1] + 1), 'is_correct' => false],
                            ['id' => 3, 'text' => (string)($cw[1] - 1), 'is_correct' => false],
                        ],
                    ],
                    'created_by' => null,
                ]
            );
            $r1Blocks[] = [
                'type' => 'activity',
                'data' => [
                    'type' => 'activity_reference',
                    'activityReferenceId' => $act->id,
                ],
            ];
        }

        $r1Blocks[] = ["type" => "header", "data" => ["text" => "Task 2: Identify Vowels & Consonants 🔤", "level" => 3]];
        $r1Blocks[] = ["type" => "paragraph", "data" => ["text" => "Read each word carefully. Identify and write the vowels and consonants found in each word."]];

        $vowelConsonantWords = [
            ["Cat", "a", "c, t"],
            ["Pen", "e", "p, n"],
            ["Fish", "i", "f, s, h"],
            ["Book", "o, o", "b, k"],
            ["Apple", "a, e", "p, p, l"],
            ["Tiger", "i, e", "t, g, r"],
            ["School", "o, o", "s, c, h, l"],
            ["Garden", "a, e", "g, r, d, n"],
            ["Orange", "o, a, e", "r, n, g"],
            ["Pencil", "e, i", "p, n, c, l"],
            ["Teacher", "e, a, e", "t, c, h, r"],
            ["Elephant", "e, e, a", "l, p, h, n, t"],
            ["Rainbow", "a, i, o", "r, n, b, w"],
            ["Football", "o, o, a", "f, t, b, l, l"],
            ["Classroom", "a, o, o", "c, l, s, s, r, m"],
            ["Butterfly", "u, e", "b, t, t, r, f, l, y"],
            ["Strawberry", "a, e", "s, t, r, w, b, r, r, y"],
            ["Playground", "a, o, u", "p, l, y, g, r, n, d"],
            ["Notebook", "o, e, o, o", "n, t, b, k"],
            ["Sunshine", "u, i, e", "s, n, s, h, n"],
        ];

        foreach ($vowelConsonantWords as $vcIdx => $vc) {
            $act = Activity::updateOrCreate(
                ['title' => "Reading Task 2 - Vowels & Consonants " . ($vcIdx + 1), 'tenant_id' => null],
                [
                    'type' => 'fill_blanks',
                    'data_json' => [
                        'question' => "Identify the vowels and consonants in \"{$vc[0]}\":",
                        'text' => "{$vc[0]} – Vowels: [{$vc[1]}] | Consonants: [{$vc[2]}]",
                    ],
                    'created_by' => null,
                ]
            );
            $r1Blocks[] = [
                'type' => 'activity',
                'data' => [
                    'type' => 'activity_reference',
                    'activityReferenceId' => $act->id,
                ],
            ];
        }

        // Reading Content 2: Jumbled Words + Compound Words
        $r2Blocks = [
            ["type" => "header", "data" => ["text" => "Task 3: Jumbled Words 🧩", "level" => 2]],
            ["type" => "paragraph", "data" => ["text" => "Rearrange the given letters to form a meaningful word. Then, read the word aloud."]],
        ];

        $jumbledWords10 = [
            ["wolfre", "flower"],
            ["lcaned", "candle"],
            ["nirat", "train"],
            ["moocnl", "column"],
            ["tescal", "castle"],
            ["kormey", "monkey"],
            ["ridgeb", "bridge"],
            ["ronwcb", "brown"],
            ["tnegar", "garden"],
            ["nlitouma", "mountain"],
        ];

        foreach ($jumbledWords10 as $jwIdx => $jw) {
            $act = Activity::updateOrCreate(
                ['title' => "Reading Task 3 - Jumbled Word " . ($jwIdx + 1), 'tenant_id' => null],
                [
                    'type' => 'fill_blanks',
                    'data_json' => [
                        'question' => "Unscramble: {$jw[0]}",
                        'text' => "{$jw[0]} → [{$jw[1]}]",
                    ],
                    'created_by' => null,
                ]
            );
            $r2Blocks[] = [
                'type' => 'activity',
                'data' => [
                    'type' => 'activity_reference',
                    'activityReferenceId' => $act->id,
                ],
            ];
        }

        $r2Blocks[] = ["type" => "header", "data" => ["text" => "COMPOUND WORDS 🔗", "level" => 2]];
        $r2Blocks[] = ["type" => "paragraph", "data" => ["text" => "A compound word is two or more words combined to express a single concept. The combined word often has a meaning that goes beyond the sum of its parts.<br><br>There are three types of compound words:<br>1. <strong>Closed compound word</strong>: Combine two words with no space or hyphen (e.g. notebook, sunflower, toothbrush).<br>2. <strong>Hyphenated compound word</strong>: Joined by a hyphen (-) (e.g. mother-in-law, well-known, check-in).<br>3. <strong>Open compound word</strong>: Two words written with a space between them (e.g. ice cream, post office, high school)."]];

        // 3 Tables of 20 Compound Words
        $closedCompounds = ["notebook", "football", "sunflower", "toothbrush", "rainbow", "classroom", "bedroom", "airport", "newspaper", "snowman", "cupcake", "firefly", "mailbox", "backpack", "basketball", "haircut", "bookshelf", "seashell", "keyboard", "moonlight"];
        $hyphenatedCompounds = ["mother-in-law", "well-known", "check-in", "self-esteem", "runner-up", "sister-in-law", "father-in-law", "twenty-one", "part-time", "full-time", "up-to-date", "long-term", "short-term", "ice-cold", "world-class", "old-fashioned", "state-of-the-art", "high-speed", "editor-in-chief", "one-sided"];
        $openCompounds = ["ice cream", "post office", "living room", "high school", "bus stop", "full moon", "real estate", "swimming pool", "coffee table", "police station", "hot dog", "science fiction", "washing machine", "dining room", "parking lot", "cell phone", "movie theatre", "fire station", "traffic light", "alarm clock"];

        $ccTable = [["S.No", "Closed Compound Word"]];
        foreach ($closedCompounds as $i => $w) $ccTable[] = [(string)($i+1), $w];

        $hcTable = [["S.No", "Hyphenated Compound Word"]];
        foreach ($hyphenatedCompounds as $i => $w) $hcTable[] = [(string)($i+1), $w];

        $ocTable = [["S.No", "Open Compound Word"]];
        foreach ($openCompounds as $i => $w) $ocTable[] = [(string)($i+1), $w];

        $r2Blocks[] = ["type" => "header", "data" => ["text" => "Closed Compound Words List", "level" => 3]];
        $r2Blocks[] = ["type" => "table", "data" => ["withHeadings" => true, "content" => $ccTable]];

        $r2Blocks[] = ["type" => "header", "data" => ["text" => "Hyphenated Compound Words List", "level" => 3]];
        $r2Blocks[] = ["type" => "table", "data" => ["withHeadings" => true, "content" => $hcTable]];

        $r2Blocks[] = ["type" => "header", "data" => ["text" => "Open Compound Words List", "level" => 3]];
        $r2Blocks[] = ["type" => "table", "data" => ["withHeadings" => true, "content" => $ocTable]];

        // Cloud Match 1 Activity
        $cloudMatchPairs1 = [
            ["left" => "Sun", "right" => "Flower"],
            ["left" => "Tooth", "right" => "Brush"],
            ["left" => "Rain", "right" => "Bow"],
            ["left" => "Class", "right" => "Room"],
            ["left" => "Foot", "right" => "Ball"],
            ["left" => "Ice", "right" => "Cream"],
            ["left" => "Post", "right" => "Office"],
            ["left" => "Living", "right" => "Room"],
            ["left" => "High", "right" => "School"],
            ["left" => "Alarm", "right" => "Clock"],
            ["left" => "Mother", "right" => "In-law"],
            ["left" => "Well", "right" => "Known"],
            ["left" => "Part", "right" => "Time"],
            ["left" => "Self", "right" => "Esteem"],
            ["left" => "Cut", "right" => "Off"],
        ];

        $actCloud1 = Activity::updateOrCreate(
            ['title' => "Cloud Match - Compound Words 1", 'tenant_id' => null],
            [
                'type' => 'match',
                'data_json' => [
                    'question' => "Match words from Cloud A and Cloud B to form compound words:",
                    'theme' => 'cloud',
                    'pairs' => $cloudMatchPairs1,
                ],
                'created_by' => null,
            ]
        );

        $r2Blocks[] = ["type" => "header", "data" => ["text" => "Task: Cloud Match 1 ☁️", "level" => 3]];
        $r2Blocks[] = [
            'type' => 'activity',
            'data' => [
                'type' => 'activity_reference',
                'activityReferenceId' => $actCloud1->id,
            ],
        ];

        // Cloud Match 2 Activity
        $cloudMatchPairs2 = [
            ["left" => "Hair", "right" => "Cut"],
            ["left" => "Long", "right" => "Term"],
            ["left" => "Traffic", "right" => "Light"],
            ["left" => "Sister", "right" => "In-law"],
            ["left" => "Fire", "right" => "Fighter"],
            ["left" => "Tea", "right" => "Spoon"],
            ["left" => "Water", "right" => "Fall"],
            ["left" => "Basket", "right" => "Ball"],
            ["left" => "Dining", "right" => "Hall"],
            ["left" => "Book", "right" => "Store"],
            ["left" => "Full", "right" => "Moon"],
            ["left" => "Check", "right" => "Up"],
            ["left" => "Bus", "right" => "Stop"],
            ["left" => "Bed", "right" => "Room"],
            ["left" => "News", "right" => "Paper"],
        ];

        $actCloud2 = Activity::updateOrCreate(
            ['title' => "Cloud Match - Compound Words 2", 'tenant_id' => null],
            [
                'type' => 'match',
                'data_json' => [
                    'question' => "Match words from Cloud A and Cloud B to form compound words (Set 2):",
                    'theme' => 'cloud',
                    'pairs' => $cloudMatchPairs2,
                ],
                'created_by' => null,
            ]
        );

        $r2Blocks[] = ["type" => "header", "data" => ["text" => "Task: Cloud Match 2 ☁️", "level" => 3]];
        $r2Blocks[] = [
            'type' => 'activity',
            'data' => [
                'type' => 'activity_reference',
                'activityReferenceId' => $actCloud2->id,
            ],
        ];

        $r2Blocks[] = ["type" => "header", "data" => ["text" => "Summary & Conclusion 🌟", "level" => 2]];
        $r2Blocks[] = ["type" => "paragraph", "data" => ["text" => "Excellent work! We have successfully completed our journey through the fundamentals of Reading Skills. We began by learning the English alphabet, explored vowels and consonants, practised counting letters, identified vowels and consonants in words, solved jumbled words, and discovered the fascinating world of compound words.<br><br><strong>Happy Reading and Keep Learning!</strong>"]];

        DB::table('content_chapters')->where('chapter_id', $chapter3->id)->delete();

        $c3_1 = Content::updateOrCreate(
            ['name' => 'Reading Skills - Alphabet, Vowels & Consonants'],
            [
                'title' => 'Reading Skills: Alphabet, Letter Count & Phonetics',
                'sort_order' => 1,
                'is_active' => true,
                'text_content' => json_encode(['time' => time(), 'blocks' => $r1Blocks, 'version' => '2.29.1'], JSON_UNESCAPED_UNICODE),
            ]
        );

        $c3_2 = Content::updateOrCreate(
            ['name' => 'Reading Skills - Jumbled & Compound Words'],
            [
                'title' => 'Reading Skills: Word Puzzles & Compound Words',
                'sort_order' => 2,
                'is_active' => true,
                'text_content' => json_encode(['time' => time(), 'blocks' => $r2Blocks, 'version' => '2.29.1'], JSON_UNESCAPED_UNICODE),
            ]
        );

        DB::table('content_chapters')->insert([
            ['content_id' => $c3_1->id, 'chapter_id' => $chapter3->id, 'sort_order' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['content_id' => $c3_2->id, 'chapter_id' => $chapter3->id, 'sort_order' => 2, 'created_at' => now(), 'updated_at' => now()],
        ]);


        // =============================================================
        // LEVEL 4: WRITING
        // =============================================================
        $level4 = Level::updateOrCreate(
            ['code' => 'LVL-WRITING-SKILLS'],
            [
                'name' => 'Level 4 - Writing & Grammar Skills',
                'description' => 'Parts of Speech, sentence arrangement, interjections & expressions, singular/plural nouns, and gerunds.',
                'sort_order' => 4,
                'is_active' => true,
            ]
        );

        DB::table('course_package_levels')->insert([
            'course_id' => $course->id,
            'package_id' => $package->id,
            'level_id' => $level4->id,
            'is_mandatory' => true,
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $chapter4_1 = Chapter::updateOrCreate(
            ['code' => 'CHP-PARTS-OF-SPEECH'],
            [
                'name' => 'Parts of Speech & Sentence Building',
                'description' => 'The 8 parts of speech, word arrangement, and emotional expressions.',
                'sort_order' => 1,
                'is_active' => true,
            ]
        );

        $chapter4_2 = Chapter::updateOrCreate(
            ['code' => 'CHP-SINGULAR-PLURAL-GERUNDS'],
            [
                'name' => 'Singular & Plural Nouns and Gerunds',
                'description' => 'Forming plural words and using verb forms ending in -ing as nouns.',
                'sort_order' => 2,
                'is_active' => true,
            ]
        );

        DB::table('level_chapter')->where('level_id', $level4->id)->delete();
        DB::table('level_chapter')->updateOrInsert(
            ['level_id' => $level4->id, 'chapter_id' => $chapter4_1->id],
            ['sort_order' => 1, 'is_active' => true, 'created_at' => now(), 'updated_at' => now()]
        );
        DB::table('level_chapter')->updateOrInsert(
            ['level_id' => $level4->id, 'chapter_id' => $chapter4_2->id],
            ['sort_order' => 2, 'is_active' => true, 'created_at' => now(), 'updated_at' => now()]
        );

        // Chapter 4_1 Content 1: 8 Parts of Speech
        $posTable = [
            ["Part of Speech", "Definition", "Examples", "Example in Sentence"],
            [
                "Noun (naming word)",
                "A naming word used to identify a person, place, animal, thing, or idea. Nouns help us talk about people, objects, feelings, and places.",
                "teacher, Chennai, book, tiger, honesty",
                "1. The teacher explained the lesson clearly.<br>2. Chennai is known for its rich cultural heritage.<br>3. I borrowed a book from the library.<br>4. The tiger is the national animal of India.<br>5. Honesty is the best policy."
            ],
            [
                "Pronoun",
                "A word used in place of a noun to avoid repeating the same noun again and again in a sentence.",
                "he, she, they, it, we, you, them, your, our, us, him, his, her, their, mine, myself, yourself, themselves.",
                "1. He won the first prize in the competition.<br>2. She sings beautifully.<br>3. They are preparing for the examination.<br>4. It is raining heavily today.<br>5. We participated in the awareness rally."
            ],
            [
                "Verb (action word)",
                "An action or doing word that shows what a person, animal, or thing does. It can also show a state of being or condition.",
                "run, sing, jump, is, are",
                "1. The athletes run every morning.<br>2. The children love to sing together.<br>3. The rabbit can jump very high.<br>4. She is a talented dancer.<br>5. The students are attentive in class."
            ],
            [
                "Adjective (describing word)",
                "A describing word that gives more information about a noun or pronoun (quality, colour, size, number, nature).",
                "beautiful, tall, red, clever, happy etc.",
                "1. She wore a beautiful dress for the function.<br>2. The tall boy plays basketball.<br>3. I bought a red pen.<br>4. The clever student solved the puzzle quickly.<br>5. The children looked happy after the picnic."
            ],
            [
                "Adverb",
                "A word that describes or modifies a verb, adjective, or another adverb (how, when, where, to what extent). Many end in '-ly'.",
                "quickly, slowly, happily, very, loudly etc.",
                "1. The boy answered the question quickly.<br>2. The old man walked slowly.<br>3. The children played happily in the park.<br>4. The lesson was very interesting.<br>5. The audience clapped loudly after the performance."
            ],
            [
                "Preposition",
                "Shows the relationship between a noun or pronoun and another word in a sentence (place, direction, position, time).",
                "in, on, under, between, near, besides, beneath, upon, across, to, etc.",
                "1. The students are in the classroom.<br>2. The book is on the table.<br>3. The cat slept under the chair.<br>4. The library is between the bank and the post office.<br>5. Our house is near the school."
            ],
            [
                "Conjunction (joining word)",
                "A joining word used to connect words, phrases, or sentences to form longer and more meaningful sentences.",
                "and, but, because, or, although",
                "1. Ravi and Priya participated in the competition.<br>2. I was tired, but I completed my homework.<br>3. She stayed at home because she was unwell.<br>4. Would you like tea or coffee?<br>5. Although it was raining, the match continued."
            ],
            [
                "Interjection",
                "Used to express sudden emotions, feelings, or reactions. Usually followed by an exclamation mark (!).",
                "wow!, alas!, hurray!, ouch!, bravo!",
                "1. Wow! The artwork is amazing.<br>2. Alas! The old tree fell during the storm.<br>3. Hurray! We won the championship.<br>4. Ouch! I hurt my finger.<br>5. Bravo! Your performance was outstanding."
            ]
        ];

        $w1Blocks = [
            ["type" => "header", "data" => ["text" => "Level 4: Writing & Grammar Skills ✍️", "level" => 2]],
            ["type" => "paragraph", "data" => ["text" => "Words are like building blocks of sentences. Every word we use has a special job to do. These jobs are called <strong>Parts of Speech</strong>. Learning parts of speech helps us speak and write English correctly and creatively.<br><br>In this module, students will learn about the eight parts of speech through fun explanations, games, activities, examples, and practice exercises."]],
            ["type" => "header", "data" => ["text" => "The Eight Parts of Speech Table 📋", "level" => 3]],
            [
                "type" => "table",
                "data" => [
                    "withHeadings" => true,
                    "content" => $posTable,
                ]
            ],
            ["type" => "header", "data" => ["text" => "Task 1: Read, Identify, and Speak 📣", "level" => 2]],
            ["type" => "paragraph", "data" => ["text" => "Read each sentence carefully and identify the part of speech of the underlined word(s):"]],
        ];

        $posExercises15 = [
            ["The little boy ran quickly to school.", "little — Adjective, quickly — Adverb"],
            ["She sang a beautiful song yesterday.", "She — Pronoun"],
            ["The cat slept under the table.", "under — Preposition"],
            ["Wow! The fireworks look amazing tonight.", "Wow! — Interjection"],
            ["My brother and I played cricket happily.", "happily — Adverb"],
            ["The old man walked slowly along the road.", "old — Adjective"],
            ["Riya bought a red dress and a blue scarf.", "and — Conjunction"],
            ["The children are sitting inside the classroom.", "inside — Preposition"],
            ["They completed the project because the teacher encouraged them.", "They — Pronoun"],
            ["The bird flew gracefully across the sky.", "gracefully — Adverb"],
            ["Hurray! Our team won the football match.", "Hurray! — Interjection"],
            ["Arun carried a heavy bag but never complained.", "but — Conjunction"],
            ["The baby is sleeping peacefully in the cradle.", "peacefully — Adverb"],
            ["The clever fox jumped over the fence.", "over — Preposition"],
            ["Ouch! The sharp thorn hurt my finger.", "Ouch! — Interjection"],
        ];

        foreach ($posExercises15 as $peIdx => $pe) {
            $act = Activity::updateOrCreate(
                ['title' => "Parts of Speech Identification " . ($peIdx + 1), 'tenant_id' => null],
                [
                    'type' => 'mcq',
                    'data_json' => [
                        'question' => "Identify the part of speech: \"{$pe[0]}\"",
                        'options' => [
                            ['id' => 1, 'text' => $pe[1], 'is_correct' => true],
                            ['id' => 2, 'text' => 'Noun', 'is_correct' => false],
                            ['id' => 3, 'text' => 'Verb', 'is_correct' => false],
                        ],
                    ],
                    'created_by' => null,
                ]
            );
            $w1Blocks[] = [
                'type' => 'activity',
                'data' => [
                    'type' => 'activity_reference',
                    'activityReferenceId' => $act->id,
                ],
            ];
        }

        // Chapter 4_1 Content 2: Word Arrangement & Interjections
        $w2Blocks = [
            ["type" => "header", "data" => ["text" => "Task 2: Word Arrangement 🧩", "level" => 2]],
            ["type" => "paragraph", "data" => ["text" => "Rearrange the given words to form a meaningful, grammatically correct sentence:"]],
        ];

        $wordArrangements10 = [
            ["football / they / playing / are", "They are playing football."],
            ["reading / book / a / is / Rani", "Rani is reading a book."],
            ["the / barking / dog / is", "The dog is barking."],
            ["cake / baking / mother / a / is", "Mother is baking a cake."],
            ["school / we / to / going / are", "We are going to school."],
            ["birds / the / singing / are", "The birds are singing."],
            ["drawing / picture / a / I / am", "I am drawing a picture."],
            ["bicycle / his / riding / Arun / is", "Arun is riding his bicycle."],
            ["dancing / stage / on / girls / the / are", "The girls are dancing on the stage."],
            ["homework / completing / my / am / I", "I am completing my homework."],
        ];

        foreach ($wordArrangements10 as $waIdx => $wa) {
            $act = Activity::updateOrCreate(
                ['title' => "Word Arrangement " . ($waIdx + 1), 'tenant_id' => null],
                [
                    'type' => 'word_arrange',
                    'data_json' => [
                        'question' => "Unscramble: {$wa[0]}",
                        'text' => $wa[0],
                        'explanation' => "Correct sentence: {$wa[1]}",
                    ],
                    'created_by' => null,
                ]
            );
            $w2Blocks[] = [
                'type' => 'activity',
                'data' => [
                    'type' => 'activity_reference',
                    'activityReferenceId' => $act->id,
                ],
            ];
        }

        $w2Blocks[] = ["type" => "header", "data" => ["text" => "Task 3: Match the Expressions (Interjections) 🎭", "level" => 2]];
        $w2Blocks[] = ["type" => "paragraph", "data" => ["text" => "Interjections are words or short expressions used to show sudden feelings or emotions. They are often followed by an exclamation mark (!).<br><br>• <strong>Wow!</strong> — Expresses surprise or admiration.<br>• <strong>Hurray!</strong> — Expresses joy, success, or celebration.<br>• <strong>Alas!</strong> — Expresses sadness, grief, or regret.<br>• <strong>Ouch!</strong> — Expresses sudden pain.<br>• <strong>Oops!</strong> — Expresses a mistake or accident.<br>• <strong>Ah!</strong> — Expresses understanding, relief, or satisfaction.<br>• <strong>Oh no!</strong> — Expresses surprise, shock, or realization.<br>• <strong>Hey!</strong> — Used to attract someone's attention.<br>• <strong>Bravo!</strong> — Expresses praise and appreciation.<br>• <strong>Yuck!</strong> — Expresses disgust or dislike.<br>• <strong>Phew!</strong> — Expresses relief after difficulty or worry.<br>• <strong>Aha!</strong> — Expresses discovery or sudden understanding.<br>• <strong>Shh!</strong> — Used to ask for silence.<br>• <strong>Hmm!</strong> — Expresses thinking, doubt, or hesitation.<br>• <strong>Gosh!</strong> — Expresses surprise, amazement, or disbelief.<br>• <strong>OMG!</strong> — Oh My God! Expresses shock or amazement.<br>• <strong>Damn!</strong> — Strong surprise, frustration, or admiration.<br>• <strong>Yay!</strong> — Happiness, excitement, delight.<br>• <strong>Aww!</strong> — Affection, sympathy, tenderness.<br>• <strong>Uh-oh!</strong> — Expresses concern or that something went wrong."]];

        $interjectionMatches = [
            ["left" => "Sudden Pain (Hurt finger)", "right" => "OUCH!"],
            ["left" => "Surprise or Admiration (Amazing fireworks)", "right" => "WOW!"],
            ["left" => "Joy or Victory (Won championship)", "right" => "HURRAY!"],
            ["left" => "Sadness or Grief (Tree fell in storm)", "right" => "ALAS!"],
            ["left" => "Praise & Appreciation (Outstanding performance)", "right" => "BRAVO!"],
            ["left" => "Small Mistake or Accident (Spilled water)", "right" => "OOPS!"],
            ["left" => "Asking for Quiet / Silence in Library", "right" => "SHH!"],
        ];

        $actInterjection = Activity::updateOrCreate(
            ['title' => "Match the Expressions - Interjections", 'tenant_id' => null],
            [
                'type' => 'match',
                'data_json' => [
                    'question' => "Match each situation with the correct interjection:",
                    'pairs' => $interjectionMatches,
                ],
                'created_by' => null,
            ]
        );

        $w2Blocks[] = [
            'type' => 'activity',
            'data' => [
                'type' => 'activity_reference',
                'activityReferenceId' => $actInterjection->id,
            ],
        ];

        DB::table('content_chapters')->where('chapter_id', $chapter4_1->id)->delete();

        $c4_1 = Content::updateOrCreate(
            ['name' => 'Writing Skills - 8 Parts of Speech'],
            [
                'title' => 'The 8 Parts of Speech & Spoken Fluency',
                'sort_order' => 1,
                'is_active' => true,
                'text_content' => json_encode(['time' => time(), 'blocks' => $w1Blocks, 'version' => '2.29.1'], JSON_UNESCAPED_UNICODE),
            ]
        );

        $c4_2 = Content::updateOrCreate(
            ['name' => 'Writing Skills - Word Arrangement & Interjections'],
            [
                'title' => 'Sentence Building & Expressive Interjections',
                'sort_order' => 2,
                'is_active' => true,
                'text_content' => json_encode(['time' => time(), 'blocks' => $w2Blocks, 'version' => '2.29.1'], JSON_UNESCAPED_UNICODE),
            ]
        );

        DB::table('content_chapters')->insert([
            ['content_id' => $c4_1->id, 'chapter_id' => $chapter4_1->id, 'sort_order' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['content_id' => $c4_2->id, 'chapter_id' => $chapter4_1->id, 'sort_order' => 2, 'created_at' => now(), 'updated_at' => now()],
        ]);

        // Chapter 4_2 Content: Singular & Plural Nouns + Gerunds
        $nounBlocks = [
            ["type" => "header", "data" => ["text" => "Singular & Plural Nouns 📚", "level" => 2]],
            ["type" => "paragraph", "data" => ["text" => "Singular and Plural Words tell us whether we are talking about one person, place, animal, thing, or idea, or more than one.<br>• Singular: refers to one (Book, Cat, Box)<br>• Plural: refers to two or more (Books, Cats, Boxes)"]],
            ["type" => "header", "data" => ["text" => "Regular Plural Rules", "level" => 3]],
            [
                "type" => "table",
                "data" => [
                    "withHeadings" => true,
                    "content" => [
                        ["Rule", "Singular", "Plural"],
                        ["Add -s", "Boat, Cat, House", "Boats, Cats, Houses"],
                        ["Ending in s, x, z, ch, sh: Add -es", "Bus, Box, Watch", "Buses, Boxes, Watches"],
                        ["Consonant + y: Change to -ies", "Baby, City, Fly", "Babies, Cities, Flies"],
                        ["Vowel + y: Add -s", "Boy, Key, Day", "Boys, Keys, Days"],
                        ["Ending in f or fe: Change to -ves", "Leaf, Knife, Wolf", "Leaves, Knives, Wolves"]
                    ]
                ]
            ],
            ["type" => "header", "data" => ["text" => "Gerunds 🏃‍♂️", "level" => 2]],
            ["type" => "paragraph", "data" => ["text" => "A gerund is a verb form ending in <strong>-ing</strong> that functions as a noun in a sentence.<br><br>Examples:<br>• <strong>Swimming</strong> is great exercise.<br>• I enjoy <strong>reading</strong> books.<br>• <strong>Painting</strong> relaxes my mind."]],
        ];

        DB::table('content_chapters')->where('chapter_id', $chapter4_2->id)->delete();

        $c4_3 = Content::updateOrCreate(
            ['name' => 'Writing Skills - Singular & Plural Nouns and Gerunds'],
            [
                'title' => 'Noun Numbers & Gerund Foundations',
                'sort_order' => 1,
                'is_active' => true,
                'text_content' => json_encode(['time' => time(), 'blocks' => $nounBlocks, 'version' => '2.29.1'], JSON_UNESCAPED_UNICODE),
            ]
        );

        DB::table('content_chapters')->insert([
            ['content_id' => $c4_3->id, 'chapter_id' => $chapter4_2->id, 'sort_order' => 1, 'created_at' => now(), 'updated_at' => now()],
        ]);

        echo "CurriculumMasterSeeder completed successfully!\n";
        echo "Course: {$course->name} (Code: {$course->code}) has 4 levels mapped to School: {$tenant->tenant_name} (Code: {$tenant->tenant_code}).\n";
    }
}
