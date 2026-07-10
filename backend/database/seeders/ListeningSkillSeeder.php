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

class ListeningSkillSeeder extends Seeder
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
            ['code' => 'LVL-LISTENING-SKILLS'],
            [
                'name' => 'Listening Skills',
                'description' => 'Listening Skills - Homophones, sounds, and active comprehension.',
                'sort_order' => 2,
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
            ['code' => 'CHP-HOMOPHONES'],
            [
                'name' => 'Homophones',
                'description' => 'Learn words that sound the same but have different meanings and spellings.',
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
            [ "type" => "header", "data" => [ "text" => "Welcome to Listening Skills! 🎧", "level" => 2 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Hai Kids! Welcome to the world of fun listening activities! Let us begin our exciting learning journey by developing one of the most important language skills — Listening." ] ],
            [ "type" => "paragraph", "data" => [ "text" => "• Listening is the first step in learning any language. Before we speak, read, or write, we first learn by listening carefully to the sounds, words, and sentences around us. Good listening helps us follow instructions, speak clearly, learn new words, and communicate confidently in English." ] ],
            [ "type" => "paragraph", "data" => [ "text" => "• Have you ever listened to the chirping of birds, the barking of dogs, or words that sound the same but have different meanings? In this module, you will explore many such interesting sounds and words through fun audio and video activities." ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Let us listen, learn, and enjoy together!" ] ],

            [ "type" => "header", "data" => [ "text" => "Homophones", "level" => 2 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Let’s learn a new and interesting concept — Homophones!" ] ],
            [ "type" => "header", "data" => [ "text" => "What are Homophones?", "level" => 3 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Have you ever heard two words that sound exactly the same but have different meanings and spellings? Those words are called Homophones. Homophones are words that sound the same but have different meanings and different spellings.<br><br><strong>HOMO</strong> means same<br><strong>PHONE</strong> means sound<br><br>So, when we put them together, Homophones means words that have the same sound. Remember, even though they sound alike, their meanings and spellings are different." ] ],

            [ "type" => "header", "data" => [ "text" => "For example, children, listen carefully:", "level" => 3 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "• <strong>I can see the blue sea from my window.</strong><br>Here, <em>sea</em> means the large water body, and <em>see</em> means to look. Both words sound the same, but their meanings are different." ] ],
            [ "type" => "paragraph", "data" => [ "text" => "• <strong>The sun is bright, and my son is playing outside.</strong><br><em>Sun</em> is the shining star in the sky, while <em>son</em> means a boy child." ] ],
            [ "type" => "paragraph", "data" => [ "text" => "• <strong>I will write my name on the right side of the page.</strong><br><em>Write</em> means to form words, and <em>right</em> means correct or a direction." ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Isn’t it interesting? Homophones make English fun and exciting to learn. So, let’s listen carefully, learn new words, and enjoy the wonderful world of homophones!" ] ],

            [ "type" => "header", "data" => [ "text" => "Try the Examples! 💡", "level" => 2 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Now, let us look at some interesting examples of homophones. Choose the correct word in brackets for each sentence." ] ]
        ];

        // 126 Homophones List
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
            ["Mail – Male", "Mail = letters; Male = boy/man"],
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
            ["Your – You’re", "Your = belonging to you; You’re = you are"]
        ];

        // Format the A to Z list dynamically into a table
        $tableContent = [["S.No", "Homophones", "Meaning"]];
        foreach ($homophonesList as $idx => $pair) {
            $tableContent[] = [(string)($idx + 1), $pair[0], $pair[1]];
        }

        $examples = [
            [
                'title' => 'Homophones Example 1',
                'type' => 'mcq',
                'data_json' => [
                    'question' => 'Choose the correct word: I can ______ the blue sea from my window.',
                    'options' => [
                        [ 'id' => 1, 'text' => 'see', 'is_correct' => true ],
                        [ 'id' => 2, 'text' => 'sea', 'is_correct' => false ]
                    ]
                ]
            ],
            [
                'title' => 'Homophones Example 2',
                'type' => 'mcq',
                'data_json' => [
                    'question' => 'Choose the correct word: I can see the blue ______ from my window.',
                    'options' => [
                        [ 'id' => 1, 'text' => 'sea', 'is_correct' => true ],
                        [ 'id' => 2, 'text' => 'see', 'is_correct' => false ]
                    ]
                ]
            ],
            [
                'title' => 'Homophones Example 3',
                'type' => 'mcq',
                'data_json' => [
                    'question' => 'Choose the correct word: The ______ is bright, and my son is playing outside.',
                    'options' => [
                        [ 'id' => 1, 'text' => 'sun', 'is_correct' => true ],
                        [ 'id' => 2, 'text' => 'son', 'is_correct' => false ]
                    ]
                ]
            ],
            [
                'title' => 'Homophones Example 4',
                'type' => 'mcq',
                'data_json' => [
                    'question' => 'Choose the correct word: The sun is bright, and my ______ is playing outside.',
                    'options' => [
                        [ 'id' => 1, 'text' => 'son', 'is_correct' => true ],
                        [ 'id' => 2, 'text' => 'sun', 'is_correct' => false ]
                    ]
                ]
            ],
            [
                'title' => 'Homophones Example 5',
                'type' => 'mcq',
                'data_json' => [
                    'question' => 'Choose the correct word: I will ______ my name on the right side of the page.',
                    'options' => [
                        [ 'id' => 1, 'text' => 'write', 'is_correct' => true ],
                        [ 'id' => 2, 'text' => 'right', 'is_correct' => false ]
                    ]
                ]
            ],
            [
                'title' => 'Homophones Example 6',
                'type' => 'mcq',
                'data_json' => [
                    'question' => 'Choose the correct word: I will write my name on the ______ side of the page.',
                    'options' => [
                        [ 'id' => 1, 'text' => 'right', 'is_correct' => true ],
                        [ 'id' => 2, 'text' => 'write', 'is_correct' => false ]
                    ]
                ]
            ]
        ];

        foreach ($examples as $ex) {
            $act = Activity::updateOrCreate(
                ['title' => $ex['title'], 'tenant_id' => null],
                [
                    'type' => $ex['type'],
                    'data_json' => $ex['data_json'],
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
        Content::where('name', 'like', 'Listening Skills Lesson%')->delete();

        $content1 = Content::create([
            'name' => 'Listening Skills Lesson - Homophones Part 1',
            'title' => 'Introduction to Listening & Homophones',
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

        // Initialize blocks2 for Part 2
        $blocks2 = [
            [ "type" => "header", "data" => [ "text" => "List of Homophones from A to Z! 📚", "level" => 2 ] ],
            [
                "type" => "table",
                "data" => [
                    "withHeadings" => true,
                    "content" => $tableContent
                ]
            ],
            [ "type" => "header", "data" => [ "text" => "Let’s Begin the Practice Exercises! 🎯", "level" => 2 ] ],
            [ "type" => "paragraph", "data" => [ "text" => "Choose the correct spelling of the homophone to complete the sentences." ] ]
        ];

        // 26 Main Exercises
        $exercises = [
            ["Please ______ my gift.", "accept", "except"],
            ["We can ______ the library online.", "access", "excess"],
            ["I saw an ______ in the newspaper.", "ad", "add"],
            ["This is the latest ______ of the book.", "edition", "addition"],
            ["Loud noise can ______ sleep.", "affect", "effect"],
            ["Students are ______ to play outside.", "allowed", "aloud"],
            ["My ______ visited us yesterday.", "aunt", "ant"],
            ["______ school is very big.", "Our", "Are"],
            ["She ______ two apples.", "ate", "eight"],
            ["A ______ is sitting on the flower.", "bee", "be"],
            ["The ______ lives in the forest.", "bear", "bare"],
            ["They ______ the treasure underground.", "bury", "berry"],
            ["The wind ______ strongly last night.", "blew", "blue"],
            ["I was ______ during the long speech.", "bored", "board"],
            ["Use the ______ before the turn.", "brake", "break"],
            ["I will ______ a new bag today.", "buy", "bye"],
            ["Chennai is the ______ of Tamil Nadu.", "capital", "capitol"],
            ["The ______ fan is new.", "ceiling", "sealing"],
            ["My father receives his ______ every month.", "salary", "celery"],
            ["They ______ fruits in the market.", "sell", "cell"],
            ["She ______ me a birthday card.", "sent", "cent"],
            ["I eat ______ every morning.", "cereal", "serial"],
            ["Please ______ your favourite colour.", "choose", "chews"],
            ["Fold your ______ neatly.", "clothes", "close"],
            ["He was ______ after the accident.", "conscious", "conscience"],
            ["The ______ met to discuss the problem.", "council", "counsel"]
        ];

        foreach ($exercises as $idx => $ex) {
            $title = "Homophones Practice " . ($idx + 1);
            
            // Alternate between MCQ, Fill Blanks, Word Arrange, and Match
            $mod = $idx % 4;

            if ($mod === 0) {
                // MCQ format
                $question = $ex[0];
                $correct = $ex[1];
                $wrong = $ex[2];

                $actJson = [
                    'question' => $question,
                    'options' => [
                        [ 'id' => 1, 'text' => $correct, 'is_correct' => true ],
                        [ 'id' => 2, 'text' => $wrong, 'is_correct' => false ]
                    ]
                ];
                $type = 'mcq';
            } 
            elseif ($mod === 1) {
                // Fill in Blanks format
                $blankText = str_replace("______", "[" . $ex[1] . "] (" . $ex[1] . " / " . $ex[2] . ")", $ex[0]);
                $actJson = [
                    'question' => 'Choose the correct word to fill in the blank.',
                    'text' => $blankText
                ];
                $type = 'fill_blanks';
            } 
            elseif ($mod === 2) {
                // Word Arrange format
                $correctSentence = str_replace("______", $ex[1], $ex[0]);
                $actJson = [
                    'question' => 'Unscramble the words to make a correct sentence.',
                    'text' => $correctSentence
                ];
                $type = 'word_arrange';
            } 
            else {
                // Matching format (using current homophone + next 2 or 3 to build match pairs)
                $pairs = [
                    [ 'left' => $ex[1], 'right' => $ex[2] ]
                ];
                
                // Add two more pairs from previous or next elements to make it a 3-pair match
                $p1 = $exercises[($idx + 1) % count($exercises)];
                $p2 = $exercises[($idx + 2) % count($exercises)];
                
                $pairs[] = [ 'left' => $p1[1], 'right' => $p1[2] ];
                $pairs[] = [ 'left' => $p2[1], 'right' => $p2[2] ];

                $actJson = [
                    'question' => 'Match the homophone pairs:',
                    'pairs' => $pairs
                ];
                $type = 'match';
            }

            $act = Activity::updateOrCreate(
                ['title' => $title, 'tenant_id' => null],
                [
                    'type' => $type,
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

        $blocks2[] = [ "type" => "header", "data" => [ "text" => "Fantastic work, kids! 🌟", "level" => 2 ] ];
        $blocks2[] = [ "type" => "paragraph", "data" => [ "text" => "You learned many interesting homophones through fun listening practice. By listening carefully and choosing the correct words, you are becoming smart and confident English learners. Keep practicing and enjoy learning new words every day." ] ];

        $content2 = Content::create([
            'name' => 'Listening Skills Lesson - Homophones Part 2',
            'title' => 'Homophones Practice',
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
    }
}
