<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Activity;
use App\Models\Course;
use Illuminate\Support\Facades\DB;

class AllActivitiesSeeder extends Seeder
{
    public function run(): void
    {
        $course = Course::where('name', 'English for Beginner')->first();
        $courseId = $course ? $course->id : null;

        // Clean up previous activities
        DB::statement('SET FOREIGN_KEY_CHECKS=0;');
        Activity::truncate();
        DB::statement('SET FOREIGN_KEY_CHECKS=1;');

        // 50 Rich MCQ Questions
        $mcqPool = [
            ['question' => 'Which of the following is an IRREGULAR past tense verb?', 'options' => [['id' => 1, 'text' => 'Walked', 'is_correct' => false], ['id' => 2, 'text' => 'Caught', 'is_correct' => true], ['id' => 3, 'text' => 'Played', 'is_correct' => false], ['id' => 4, 'text' => 'Opened', 'is_correct' => false]], 'explanation' => '"Catch" becomes "Caught", an irregular form.'],
            ['question' => 'Choose the correct ANTONYM for "ANCIENT":', 'options' => [['id' => 1, 'text' => 'Historic', 'is_correct' => false], ['id' => 2, 'text' => 'Modern', 'is_correct' => true], ['id' => 3, 'text' => 'Antique', 'is_correct' => false], ['id' => 4, 'text' => 'Prehistoric', 'is_correct' => false]], 'explanation' => '"Modern" means of the present time, opposite to "Ancient".'],
            ['question' => 'Identify the ADVERB in: "The cheetah ran exceptionally fast."', 'options' => [['id' => 1, 'text' => 'Cheetah', 'is_correct' => false], ['id' => 2, 'text' => 'Ran', 'is_correct' => false], ['id' => 3, 'text' => 'Exceptionally', 'is_correct' => true], ['id' => 4, 'text' => 'Fast', 'is_correct' => false]], 'explanation' => '"Exceptionally" is an adverb modifying fast.'],
            ['question' => 'Select the correct PLURAL form of "CRISIS":', 'options' => [['id' => 1, 'text' => 'Crisises', 'is_correct' => false], ['id' => 2, 'text' => 'Crises', 'is_correct' => true], ['id' => 3, 'text' => 'Crisii', 'is_correct' => false]], 'explanation' => 'Nouns ending in -is become -es in plural.'],
            ['question' => 'Complete with preposition: "She has been learning English ___ five years."', 'options' => [['id' => 1, 'text' => 'Since', 'is_correct' => false], ['id' => 2, 'text' => 'For', 'is_correct' => true], ['id' => 3, 'text' => 'During', 'is_correct' => false]], 'explanation' => '"For" is used for periods/durations.'],
            ['question' => 'What is the past tense of "FREEZE"?', 'options' => [['id' => 1, 'text' => 'Froze', 'is_correct' => true], ['id' => 2, 'text' => 'Freezed', 'is_correct' => false], ['id' => 3, 'text' => 'Frozen', 'is_correct' => false]], 'explanation' => '"Freeze" becomes "Froze".'],
            ['question' => 'Choose the SYNONYM for "BENEVOLENT":', 'options' => [['id' => 1, 'text' => 'Cruel', 'is_correct' => false], ['id' => 2, 'text' => 'Kind', 'is_correct' => true], ['id' => 3, 'text' => 'Greedy', 'is_correct' => false]], 'explanation' => '"Benevolent" means well-meaning and kindly.'],
            ['question' => 'Select the correct plural of "TOOTH":', 'options' => [['id' => 1, 'text' => 'Tooths', 'is_correct' => false], ['id' => 2, 'text' => 'Teeth', 'is_correct' => true], ['id' => 3, 'text' => 'Toothes', 'is_correct' => false]], 'explanation' => '"Tooth" becomes "Teeth".'],
            ['question' => 'Which word is a CONJUNCTION?', 'options' => [['id' => 1, 'text' => 'Quickly', 'is_correct' => false], ['id' => 2, 'text' => 'Because', 'is_correct' => true], ['id' => 3, 'text' => 'Beautiful', 'is_correct' => false]], 'explanation' => '"Because" connects clauses.'],
            ['question' => 'Choose the homophone: "I want to ___ a bicycle."', 'options' => [['id' => 1, 'text' => 'Bye', 'is_correct' => false], ['id' => 2, 'text' => 'Buy', 'is_correct' => true], ['id' => 3, 'text' => 'By', 'is_correct' => false]], 'explanation' => '"Buy" means to purchase.'],
            ['question' => 'What part of speech is "GENTLY"?', 'options' => [['id' => 1, 'text' => 'Adjective', 'is_correct' => false], ['id' => 2, 'text' => 'Adverb', 'is_correct' => true], ['id' => 3, 'text' => 'Noun', 'is_correct' => false]], 'explanation' => 'Words telling HOW an action is performed are adverbs.'],
            ['question' => 'Antonym of "TRANSPARENT":', 'options' => [['id' => 1, 'text' => 'Clear', 'is_correct' => false], ['id' => 2, 'text' => 'Opaque', 'is_correct' => true], ['id' => 3, 'text' => 'Bright', 'is_correct' => false]], 'explanation' => '"Opaque" means not transparent.'],
            ['question' => 'Past participle of "SPEAK":', 'options' => [['id' => 1, 'text' => 'Spoke', 'is_correct' => false], ['id' => 2, 'text' => 'Spoken', 'is_correct' => true], ['id' => 3, 'text' => 'Speaked', 'is_correct' => false]], 'explanation' => 'Speak -> Spoke -> Spoken.'],
            ['question' => 'Plural of "MOUSE" (animal):', 'options' => [['id' => 1, 'text' => 'Mouses', 'is_correct' => false], ['id' => 2, 'text' => 'Mice', 'is_correct' => true], ['id' => 3, 'text' => 'Mices', 'is_correct' => false]], 'explanation' => 'Plural is "Mice".'],
            ['question' => 'What is an ABSTRACT NOUN?', 'options' => [['id' => 1, 'text' => 'Bravery', 'is_correct' => true], ['id' => 2, 'text' => 'Sword', 'is_correct' => false], ['id' => 3, 'text' => 'Soldier', 'is_correct' => false]], 'explanation' => '"Bravery" is a concept/feeling.'],
            ['question' => 'Past tense of "SWIM":', 'options' => [['id' => 1, 'text' => 'Swum', 'is_correct' => false], ['id' => 2, 'text' => 'Swam', 'is_correct' => true], ['id' => 3, 'text' => 'Swimed', 'is_correct' => false]], 'explanation' => 'Past tense is "Swam".'],
            ['question' => 'Collective noun for lions: "A ___ of lions slept."', 'options' => [['id' => 1, 'text' => 'Flock', 'is_correct' => false], ['id' => 2, 'text' => 'Pride', 'is_correct' => true], ['id' => 3, 'text' => 'Pack', 'is_correct' => false]], 'explanation' => '"Pride" is the group name for lions.'],
            ['question' => 'Choose the correct word: "The dog wagged ___ tail."', 'options' => [['id' => 1, 'text' => "it's", 'is_correct' => false], ['id' => 2, 'text' => 'its', 'is_correct' => true], ['id' => 3, 'text' => 'it', 'is_correct' => false]], 'explanation' => '"Its" is possessive.'],
            ['question' => 'Plural of "KNIFE":', 'options' => [['id' => 1, 'text' => 'Knifes', 'is_correct' => false], ['id' => 2, 'text' => 'Knives', 'is_correct' => true], ['id' => 3, 'text' => 'Knifeses', 'is_correct' => false]], 'explanation' => 'F/fe changes to -ves: "Knives".'],
            ['question' => 'Antonym of "GENEROUS":', 'options' => [['id' => 1, 'text' => 'Stingy', 'is_correct' => true], ['id' => 2, 'text' => 'Kind', 'is_correct' => false], ['id' => 3, 'text' => 'Polite', 'is_correct' => false]], 'explanation' => '"Stingy" is the opposite of generous.'],
            ['question' => 'Past tense of "FLY":', 'options' => [['id' => 1, 'text' => 'Flied', 'is_correct' => false], ['id' => 2, 'text' => 'Flew', 'is_correct' => true], ['id' => 3, 'text' => 'Flown', 'is_correct' => false]], 'explanation' => 'Past tense of fly is "Flew".'],
            ['question' => 'Choose article: "He is ___ honest student."', 'options' => [['id' => 1, 'text' => 'a', 'is_correct' => false], ['id' => 2, 'text' => 'an', 'is_correct' => true], ['id' => 3, 'text' => 'the', 'is_correct' => false]], 'explanation' => '"Honest" starts with vowel sound, takes "an".'],
            ['question' => 'What does "Piece of cake" mean?', 'options' => [['id' => 1, 'text' => 'Dessert', 'is_correct' => false], ['id' => 2, 'text' => 'Very easy', 'is_correct' => true], ['id' => 3, 'text' => 'Difficult task', 'is_correct' => false]], 'explanation' => 'Idiom meaning very easy.'],
            ['question' => 'Plural of "PERSON":', 'options' => [['id' => 1, 'text' => 'Persons', 'is_correct' => false], ['id' => 2, 'text' => 'People', 'is_correct' => true], ['id' => 3, 'text' => 'Peoples', 'is_correct' => false]], 'explanation' => 'Regular plural of person is "People".'],
            ['question' => 'Superlative of "GOOD":', 'options' => [['id' => 1, 'text' => 'Better', 'is_correct' => false], ['id' => 2, 'text' => 'Best', 'is_correct' => true], ['id' => 3, 'text' => 'Goodest', 'is_correct' => false]], 'explanation' => 'Good -> Better -> Best.'],
            ['question' => 'Past tense of "BRING":', 'options' => [['id' => 1, 'text' => 'Brought', 'is_correct' => true], ['id' => 2, 'text' => 'Brang', 'is_correct' => false], ['id' => 3, 'text' => 'Bringed', 'is_correct' => false]], 'explanation' => 'Bring becomes "Brought".'],
            ['question' => 'Plural of "OX":', 'options' => [['id' => 1, 'text' => 'Oxes', 'is_correct' => false], ['id' => 2, 'text' => 'Oxen', 'is_correct' => true], ['id' => 3, 'text' => 'Oxi', 'is_correct' => false]], 'explanation' => 'Plural of ox is "Oxen".'],
            ['question' => 'Antonym of "EXPAND":', 'options' => [['id' => 1, 'text' => 'Shrink', 'is_correct' => true], ['id' => 2, 'text' => 'Grow', 'is_correct' => false], ['id' => 3, 'text' => 'Widen', 'is_correct' => false]], 'explanation' => '"Shrink" is opposite of expand.'],
            ['question' => 'Plural of "SHEEP":', 'options' => [['id' => 1, 'text' => 'Sheeps', 'is_correct' => false], ['id' => 2, 'text' => 'Sheep', 'is_correct' => true], ['id' => 3, 'text' => 'Shoop', 'is_correct' => false]], 'explanation' => 'Sheep remains "Sheep" in plural.'],
            ['question' => 'Past tense of "THINK":', 'options' => [['id' => 1, 'text' => 'Thought', 'is_correct' => true], ['id' => 2, 'text' => 'Thunk', 'is_correct' => false], ['id' => 3, 'text' => 'Thinked', 'is_correct' => false]], 'explanation' => 'Think becomes "Thought".'],
            ['question' => 'Plural of "LEAF":', 'options' => [['id' => 1, 'text' => 'Leafs', 'is_correct' => false], ['id' => 2, 'text' => 'Leaves', 'is_correct' => true], ['id' => 3, 'text' => 'Leafes', 'is_correct' => false]], 'explanation' => 'Leaf becomes "Leaves".'],
            ['question' => 'Past tense of "CHOOSE":', 'options' => [['id' => 1, 'text' => 'Choosed', 'is_correct' => false], ['id' => 2, 'text' => 'Chose', 'is_correct' => true], ['id' => 3, 'text' => 'Chosen', 'is_correct' => false]], 'explanation' => 'Choose becomes "Chose".'],
            ['question' => 'Past tense of "EAT":', 'options' => [['id' => 1, 'text' => 'Ate', 'is_correct' => true], ['id' => 2, 'text' => 'Eaten', 'is_correct' => false], ['id' => 3, 'text' => 'Eated', 'is_correct' => false]], 'explanation' => 'Eat becomes "Ate".'],
            ['question' => 'Past tense of "DRIVE":', 'options' => [['id' => 1, 'text' => 'Drove', 'is_correct' => true], ['id' => 2, 'text' => 'Driven', 'is_correct' => false], ['id' => 3, 'text' => 'Drived', 'is_correct' => false]], 'explanation' => 'Drive becomes "Drove".'],
            ['question' => 'Past tense of "WRITE":', 'options' => [['id' => 1, 'text' => 'Wrote', 'is_correct' => true], ['id' => 2, 'text' => 'Written', 'is_correct' => false], ['id' => 3, 'text' => 'Writed', 'is_correct' => false]], 'explanation' => 'Write becomes "Wrote".'],
            ['question' => 'Past tense of "GO":', 'options' => [['id' => 1, 'text' => 'Went', 'is_correct' => true], ['id' => 2, 'text' => 'Gone', 'is_correct' => false], ['id' => 3, 'text' => 'Goed', 'is_correct' => false]], 'explanation' => 'Go becomes "Went".'],
            ['question' => 'Past tense of "BUY":', 'options' => [['id' => 1, 'text' => 'Bought', 'is_correct' => true], ['id' => 2, 'text' => 'Buyed', 'is_correct' => false], ['id' => 3, 'text' => 'Buying', 'is_correct' => false]], 'explanation' => 'Buy becomes "Bought".'],
            ['question' => 'Past tense of "SING":', 'options' => [['id' => 1, 'text' => 'Sang', 'is_correct' => true], ['id' => 2, 'text' => 'Sung', 'is_correct' => false], ['id' => 3, 'text' => 'Singed', 'is_correct' => false]], 'explanation' => 'Sing becomes "Sang".'],
            ['question' => 'Past tense of "BREAK":', 'options' => [['id' => 1, 'text' => 'Broke', 'is_correct' => true], ['id' => 2, 'text' => 'Broken', 'is_correct' => false], ['id' => 3, 'text' => 'Breaked', 'is_correct' => false]], 'explanation' => 'Break becomes "Broke".'],
            ['question' => 'Past tense of "CATCH":', 'options' => [['id' => 1, 'text' => 'Caught', 'is_correct' => true], ['id' => 2, 'text' => 'Catched', 'is_correct' => false], ['id' => 3, 'text' => 'Catching', 'is_correct' => false]], 'explanation' => 'Catch becomes "Caught".'],
            ['question' => 'Past tense of "DRAW":', 'options' => [['id' => 1, 'text' => 'Drew', 'is_correct' => true], ['id' => 2, 'text' => 'Drawn', 'is_correct' => false], ['id' => 3, 'text' => 'Drawed', 'is_correct' => false]], 'explanation' => 'Draw becomes "Drew".'],
            ['question' => 'Past tense of "DRINK":', 'options' => [['id' => 1, 'text' => 'Drank', 'is_correct' => true], ['id' => 2, 'text' => 'Drunk', 'is_correct' => false], ['id' => 3, 'text' => 'Drinked', 'is_correct' => false]], 'explanation' => 'Drink becomes "Drank".'],
            ['question' => 'Past tense of "FALL":', 'options' => [['id' => 1, 'text' => 'Fell', 'is_correct' => true], ['id' => 2, 'text' => 'Fallen', 'is_correct' => false], ['id' => 3, 'text' => 'Falled', 'is_correct' => false]], 'explanation' => 'Fall becomes "Fell".'],
            ['question' => 'Past tense of "GIVE":', 'options' => [['id' => 1, 'text' => 'Gave', 'is_correct' => true], ['id' => 2, 'text' => 'Given', 'is_correct' => false], ['id' => 3, 'text' => 'Gived', 'is_correct' => false]], 'explanation' => 'Give becomes "Gave".'],
            ['question' => 'Past tense of "GROW":', 'options' => [['id' => 1, 'text' => 'Grew', 'is_correct' => true], ['id' => 2, 'text' => 'Grown', 'is_correct' => false], ['id' => 3, 'text' => 'Growed', 'is_correct' => false]], 'explanation' => 'Grow becomes "Grew".'],
            ['question' => 'Past tense of "KNOW":', 'options' => [['id' => 1, 'text' => 'Knew', 'is_correct' => true], ['id' => 2, 'text' => 'Known', 'is_correct' => false], ['id' => 3, 'text' => 'Knowed', 'is_correct' => false]], 'explanation' => 'Know becomes "Knew".'],
            ['question' => 'Past tense of "LEAVE":', 'options' => [['id' => 1, 'text' => 'Left', 'is_correct' => true], ['id' => 2, 'text' => 'Leaved', 'is_correct' => false], ['id' => 3, 'text' => 'Leaving', 'is_correct' => false]], 'explanation' => 'Leave becomes "Left".'],
            ['question' => 'Past tense of "RUN":', 'options' => [['id' => 1, 'text' => 'Ran', 'is_correct' => true], ['id' => 2, 'text' => 'Runned', 'is_correct' => false], ['id' => 3, 'text' => 'Running', 'is_correct' => false]], 'explanation' => 'Run becomes "Ran".'],
            ['question' => 'Past tense of "SEE":', 'options' => [['id' => 1, 'text' => 'Saw', 'is_correct' => true], ['id' => 2, 'text' => 'Seen', 'is_correct' => false], ['id' => 3, 'text' => 'Seed', 'is_correct' => false]], 'explanation' => 'See becomes "Saw".'],
            ['question' => 'Past tense of "TAKE":', 'options' => [['id' => 1, 'text' => 'Took', 'is_correct' => true], ['id' => 2, 'text' => 'Taken', 'is_correct' => false], ['id' => 3, 'text' => 'Taked', 'is_correct' => false]], 'explanation' => 'Take becomes "Took".'],
        ];

        // 50 Match Pairs
        $matchPairs = [
            ['left' => 'Sun', 'right' => 'Flower', 'result' => 'Sunflower'],
            ['left' => 'Rain', 'right' => 'Bow', 'result' => 'Rainbow'],
            ['left' => 'Jelly', 'right' => 'Fish', 'result' => 'Jellyfish'],
            ['left' => 'Ice', 'right' => 'Cream', 'result' => 'Ice cream'],
            ['left' => 'Tooth', 'right' => 'Brush', 'result' => 'Toothbrush'],
            ['left' => 'Butter', 'right' => 'Fly', 'result' => 'Butterfly'],
            ['left' => 'Star', 'right' => 'Fish', 'result' => 'Starfish'],
            ['left' => 'Snow', 'right' => 'Man', 'result' => 'Snowman'],
            ['left' => 'Book', 'right' => 'Shelf', 'result' => 'Bookshelf'],
            ['left' => 'Dragon', 'right' => 'Fly', 'result' => 'Dragonfly'],
            ['left' => 'Cup', 'right' => 'Cake', 'result' => 'Cupcake'],
            ['left' => 'Sea', 'right' => 'Shell', 'result' => 'Seashell'],
            ['left' => 'Pan', 'right' => 'Cake', 'result' => 'Pancake'],
            ['left' => 'Door', 'right' => 'Bell', 'result' => 'Doorbell'],
            ['left' => 'Bed', 'right' => 'Room', 'result' => 'Bedroom'],
            ['left' => 'Arm', 'right' => 'Chair', 'result' => 'Armchair'],
            ['left' => 'Foot', 'right' => 'Ball', 'result' => 'Football'],
            ['left' => 'Camp', 'right' => 'Fire', 'result' => 'Campfire'],
            ['left' => 'Enormous', 'right' => 'Extremely Large', 'result' => 'Synonym'],
            ['left' => 'Ancient', 'right' => 'Belonging to Past', 'result' => 'Synonym'],
            ['left' => 'Brilliant', 'right' => 'Exceptionally Clever', 'result' => 'Synonym'],
            ['left' => 'Silent', 'right' => 'Completely Quiet', 'result' => 'Synonym'],
            ['left' => 'Swift', 'right' => 'Moving Very Fast', 'result' => 'Synonym'],
            ['left' => 'Fragile', 'right' => 'Easily Broken', 'result' => 'Synonym'],
            ['left' => 'Courageous', 'right' => 'Extremely Brave', 'result' => 'Synonym'],
            ['left' => 'Miniature', 'right' => 'Very Small', 'result' => 'Synonym'],
            ['left' => 'Furious', 'right' => 'Extremely Angry', 'result' => 'Synonym'],
            ['left' => 'Exhausted', 'right' => 'Extremely Tired', 'result' => 'Synonym'],
            ['left' => 'Benevolent', 'right' => 'Kind & Charitable', 'result' => 'Synonym'],
            ['left' => 'Opaque', 'right' => 'Not Transparent', 'result' => 'Antonym'],
            ['left' => 'Genuine', 'right' => 'Real and Authentic', 'result' => 'Synonym'],
            ['left' => 'Abundant', 'right' => 'Existing in Plenty', 'result' => 'Synonym'],
            ['left' => 'Cautious', 'right' => 'Very Careful', 'result' => 'Synonym'],
            ['left' => 'Humble', 'right' => 'Modest & Respectful', 'result' => 'Synonym'],
            ['left' => 'Perilous', 'right' => 'Dangerous & Risky', 'result' => 'Synonym'],
            ['left' => 'Vivid', 'right' => 'Bright & Intense', 'result' => 'Synonym'],
            ['left' => 'Gleeful', 'right' => 'Full of Joy', 'result' => 'Synonym'],
            ['left' => 'Peculiar', 'right' => 'Strange or Unusual', 'result' => 'Synonym'],
            ['left' => 'Gargantuan', 'right' => 'Colossal & Gigantic', 'result' => 'Synonym'],
            ['left' => 'Tranquil', 'right' => 'Calm and Peaceful', 'result' => 'Synonym'],
            ['left' => 'Meticulous', 'right' => 'Careful with Details', 'result' => 'Synonym'],
            ['left' => 'Audacious', 'right' => 'Willing to Take Risks', 'result' => 'Synonym'],
            ['left' => 'Candid', 'right' => 'Direct and Honest', 'result' => 'Synonym'],
            ['left' => 'Lucid', 'right' => 'Clear and Expressive', 'result' => 'Synonym'],
            ['left' => 'Tenacious', 'right' => 'Determined & Persistent', 'result' => 'Synonym'],
            ['left' => 'Resilient', 'right' => 'Recovering Quickly', 'result' => 'Synonym'],
            ['left' => 'Novice', 'right' => 'Beginner with No Exp', 'result' => 'Synonym'],
            ['left' => 'Veteran', 'right' => 'Experienced & Skilled', 'result' => 'Synonym'],
            ['left' => 'Brave', 'right' => 'Cowardly', 'result' => 'Antonym'],
            ['left' => 'Hot', 'right' => 'Freezing', 'result' => 'Antonym']
        ];

        // 50 Car Racer Rounds
        $racerRounds = [];
        $racerPoolData = [
            ['Drive', 'Drove', 'Drived', 'Drives'],
            ['Write', 'Wrote', 'Writing', 'Written'],
            ['Go', 'Went', 'Goes', 'Going'],
            ['Eat', 'Ate', 'Eating', 'Eaten'],
            ['Buy', 'Bought', 'Buyed', 'Buying'],
            ['Sing', 'Sang', 'Singed', 'Sung'],
            ['Fly', 'Flew', 'Flied', 'Flown'],
            ['Swim', 'Swam', 'Swimed', 'Swum'],
            ['Run', 'Ran', 'Runned', 'Running'],
            ['Break', 'Broke', 'Breaked', 'Broken'],
            ['Catch', 'Caught', 'Catched', 'Catching'],
            ['Speak', 'Spoke', 'Speaked', 'Spoken'],
            ['Sleep', 'Slept', 'Sleeped', 'Sleeping'],
            ['Begin', 'Began', 'Begun', 'Beginned'],
            ['Blow', 'Blew', 'Blowed', 'Blown'],
            ['Choose', 'Chose', 'Choosed', 'Chosen'],
            ['Draw', 'Drew', 'Drawed', 'Drawn'],
            ['Drink', 'Drank', 'Drunk', 'Drinked'],
            ['Fall', 'Fell', 'Fallen', 'Falled'],
            ['Feel', 'Felt', 'Feeled', 'Feeling'],
            ['Fight', 'Fought', 'Fighted', 'Fighting'],
            ['Find', 'Found', 'Finded', 'Finding'],
            ['Forget', 'Forgot', 'Forgotten', 'Forgetted'],
            ['Freeze', 'Froze', 'Frozen', 'Freezed'],
            ['Give', 'Gave', 'Given', 'Gived'],
            ['Grow', 'Grew', 'Grown', 'Growed'],
            ['Hear', 'Heard', 'Heared', 'Hearing'],
            ['Hide', 'Hid', 'Hidden', 'Hided'],
            ['Hold', 'Held', 'Holded', 'Holding'],
            ['Keep', 'Kept', 'Keeped', 'Keeping'],
            ['Know', 'Knew', 'Known', 'Knowed'],
            ['Lead', 'Led', 'Leaded', 'Leading'],
            ['Leave', 'Left', 'Leaved', 'Leaving'],
            ['Lose', 'Lost', 'Losed', 'Loosed'],
            ['Make', 'Made', 'Maked', 'Making'],
            ['Meet', 'Met', 'Meeted', 'Meeting'],
            ['Pay', 'Paid', 'Payed', 'Paying'],
            ['Ride', 'Rode', 'Rided', 'Ridden'],
            ['Ring', 'Rang', 'Rung', 'Ringed'],
            ['Rise', 'Rose', 'Risen', 'Rised'],
            ['See', 'Saw', 'Seen', 'Seed'],
            ['Sell', 'Sold', 'Selled', 'Selling'],
            ['Send', 'Sent', 'Sended', 'Sending'],
            ['Shake', 'Shook', 'Shaked', 'Shaken'],
            ['Stand', 'Stood', 'Standed', 'Standing'],
            ['Steal', 'Stole', 'Stealed', 'Stolen'],
            ['Take', 'Took', 'Taken', 'Taked'],
            ['Teach', 'Taught', 'Teached', 'Teaching'],
            ['Think', 'Thought', 'Thinked', 'Thinking'],
            ['Win', 'Won', 'Winned', 'Winning']
        ];

        foreach ($racerPoolData as $item) {
            $racerRounds[] = [
                'question' => "Steer to the Past Tense of \"{$item[0]}\":",
                'options' => [
                    ['text' => $item[1], 'isCorrect' => true],
                    ['text' => $item[2], 'isCorrect' => false],
                    ['text' => $item[3], 'isCorrect' => false],
                ]
            ];
        }

        // 50 Flappy Word Gates
        $flappyGates = [];
        foreach ($racerPoolData as $item) {
            $flappyGates[] = [
                'target' => $item[1],
                'distractor' => $item[2]
            ];
        }

        // 50 Fill in the Blanks sentences
        $fillBlanksPool = [
            ['text' => 'The sun [rises] in the east and sets in the [west].'],
            ['text' => 'She decided to [listen] carefully to the teacher during class.'],
            ['text' => 'They went to the library to [borrow] books for the science project.'],
            ['text' => 'Water [boils] at 100 degrees Celsius.'],
            ['text' => 'The keys are lying [on] the dining table.'],
            ['text' => 'If it rains tomorrow, we [will] stay inside the house.'],
            ['text' => 'Yesterday, our team [won] the championship trophy.'],
            ['text' => 'Neither Peter nor his brother brought [his] backpack.'],
            ['text' => 'The ballerina danced [gracefully] across the grand stage.'],
            ['text' => 'The train arrives [at] the station in five minutes.'],
            ['text' => 'They have [finished] all their chores before dinner.'],
            ['text' => 'This is the author [who] wrote the award-winning book.'],
            ['text' => 'Today is the [hottest] day of the entire year.'],
            ['text' => 'We hurried to the airport [so that] we wouldn\'t miss our flight.'],
            ['text' => 'The submarine dove deep [below] the ocean surface.'],
            ['text' => 'He [brushes] his teeth every morning and evening.'],
            ['text' => 'A large [flock] of birds flew across the sunset sky.'],
            ['text' => 'She is both intelligent [and] hardworking.'],
            ['text' => 'The chef prepared a [delicious] meal for all the guests.'],
            ['text' => 'You must drive [carefully] when the road is slippery.'],
            ['text' => 'The package was delivered [by] the postal worker.'],
            ['text' => 'He had already left [when] I arrived at the cafe.'],
            ['text' => 'I bought a new pair of [shoes] for running in the park.'],
            ['text' => 'The majestic eagle soared high above the [mountains].'],
            ['text' => 'She prefers drinking tea [rather than] coffee in the morning.'],
            ['text' => 'The baby fell fast [asleep] after drinking warm milk.'],
            ['text' => 'We should always protect our [environment] from pollution.'],
            ['text' => 'The ancient castle was surrounded by a deep [moat].'],
            ['text' => 'He spoke with great [confidence] in front of the audience.'],
            ['text' => 'The gardener planted colorful [flowers] in the backyard.'],
            ['text' => 'Neither rain [nor] snow stopped the courier from delivering.'],
            ['text' => 'She wore a warm woolen [sweater] during the cold winter night.'],
            ['text' => 'The scientist discovered a [cure] for the rare disease.'],
            ['text' => 'Practice makes a person [perfect] in any skill.'],
            ['text' => 'The lion is widely known as the [king] of the jungle.'],
            ['text' => 'They visited the museum to [see] historical artifacts.'],
            ['text' => 'He opened the window to let fresh [air] into the room.'],
            ['text' => 'The airplane took [off] smoothly on schedule.'],
            ['text' => 'She solved the complicated puzzle in just five [minutes].'],
            ['text' => 'Honey is produced by industrious [bees] in the hive.'],
            ['text' => 'The old clock [chimed] twelve times at midnight.'],
            ['text' => 'You need a valid [passport] to travel abroad.'],
            ['text' => 'The moon shines brightly in the [night] sky.'],
            ['text' => 'He apologized sincerely [for] his unintentional mistake.'],
            ['text' => 'The detective found a crucial [clue] at the scene.'],
            ['text' => 'Good health is the greatest of all [blessings].'],
            ['text' => 'The children played [happily] in the green playground.'],
            ['text' => 'An apple a day keeps the [doctor] away.'],
            ['text' => 'Honesty is always the best [policy].'],
            ['text' => 'Knowledge is [power] that opens many doors in life.']
        ];

        // 50 Flashcards
        $flashcardPool = [
            ['front' => 'What is a **Noun**?', 'back' => 'A noun is a word representing a person, place, thing, or idea (e.g., *teacher*, *city*, *pencil*, *courage*).'],
            ['front' => 'What is an **Adjective**?', 'back' => 'An adjective describes or modifies a noun or pronoun (e.g., *happy*, *clever*, *bright*, *resilient*).'],
            ['front' => 'What is a **Verb**?', 'back' => 'A verb expresses an action, state of being, or occurrence (e.g., *run*, *think*, *exist*, *transform*).'],
            ['front' => 'What is an **Adverb**?', 'back' => 'An adverb modifies a verb, adjective, or another adverb (e.g., *quickly*, *very*, *silently*).'],
            ['front' => 'What is a **Pronoun**?', 'back' => 'A pronoun replaces a noun to avoid repetition (e.g., *he*, *she*, *they*, *it*, *who*).'],
            ['front' => 'What is a **Preposition**?', 'back' => 'A preposition shows relationship between a noun and other words (e.g., *in*, *on*, *under*, *through*).'],
            ['front' => 'What is a **Conjunction**?', 'back' => 'A conjunction connects words, phrases, or clauses (e.g., *and*, *but*, *because*, *although*).'],
            ['front' => 'What is an **Interjection**?', 'back' => 'An interjection expresses sudden emotion or exclamation (e.g., *Wow!*, *Ouch!*, *Hooray!*).'],
            ['front' => 'What is a **Synonym**?', 'back' => 'A word that has the same or very similar meaning to another (e.g., *huge* and *enormous*).'],
            ['front' => 'What is an **Antonym**?', 'back' => 'A word opposite in meaning to another word (e.g., *ancient* and *modern*).'],
            ['front' => 'What is a **Homophone**?', 'back' => 'Words with identical pronunciation but different spelling and meaning (e.g., *sea* and *see*).'],
            ['front' => 'What is a **Prefix**?', 'back' => 'A letter or group of letters added to the beginning of a word (e.g., *un-* in *unhappy*).'],
            ['front' => 'What is a **Suffix**?', 'back' => 'A letter or group of letters added to the end of a word (e.g., *-ful* in *cheerful*).'],
            ['front' => 'What is a **Metaphor**?', 'back' => 'A direct comparison between two unrelated things without using like or as (e.g., *Time is a thief*).'],
            ['front' => 'What is a **Simile**?', 'back' => 'A comparison using the words *like* or *as* (e.g., *As brave as a lion*).'],
            ['front' => 'What is **Alliteration**?', 'back' => 'Repetition of the same initial consonant sound in adjacent words (e.g., *Peter Piper picked*).'],
            ['front' => 'What is **Personification**?', 'back' => 'Giving human traits or emotions to non-human objects (e.g., *The wind whispered*).'],
            ['front' => 'What is an **Idiom**?', 'back' => 'A phrase whose meaning cannot be deduced from literal words (e.g., *Bite the bullet*).'],
            ['front' => 'What is an **Abstract Noun**?', 'back' => 'A noun denoting an idea, quality, or state rather than a concrete object (e.g., *freedom*, *love*).'],
            ['front' => 'What is a **Collective Noun**?', 'back' => 'A noun referring to a group or collection of things (e.g., *a flock of birds*, *a pride of lions*).'],
            ['front' => 'What is an **Irregular Verb**?', 'back' => 'A verb whose past tense is not formed by adding -ed (e.g., *go -> went*, *eat -> ate*).'],
            ['front' => 'What is a **Compound Word**?', 'back' => 'Two words joined to create a new word with a new meaning (e.g., *sunflower*, *notebook*).'],
            ['front' => 'What is an **Oxymoron**?', 'back' => 'A figure of speech where contradictory terms appear together (e.g., *deafening silence*).'],
            ['front' => 'What is a **Hyperbole**?', 'back' => 'An exaggerated statement not meant to be taken literally (e.g., *I have told you a million times*).'],
            ['front' => 'What is an **Anagram**?', 'back' => 'A word formed by rearranging the letters of another (e.g., *cinema* -> *iceman*).'],
            ['front' => 'What is a **Palindrome**?', 'back' => 'A word or phrase reading the same forwards and backwards (e.g., *racecar*, *madam*).'],
            ['front' => 'What is a **Gerund**?', 'back' => 'A verb form ending in -ing that functions as a noun (e.g., *Swimming is great exercise*).'],
            ['front' => 'What is an **Infinitive**?', 'back' => 'The base form of a verb typically preceded by *to* (e.g., *to learn*, *to read*).'],
            ['front' => 'What is a **Participle**?', 'back' => 'A verb form that functions as an adjective (e.g., *the running water*, *a broken vase*).'],
            ['front' => 'What is an **Acronym**?', 'back' => 'An abbreviation formed from the initial letters of other words (e.g., *NASA*, *UNESCO*).'],
            ['front' => 'What is a **Portmanteau**?', 'back' => 'A word blending the sounds and meanings of two words (e.g., *smoke + fog = smog*).'],
            ['front' => 'What is **Onomatopoeia**?', 'back' => 'A word that phonetically imitates the source sound (e.g., *buzz*, *splash*, *boom*).'],
            ['front' => 'What is an **Adverb of Frequency**?', 'back' => 'Tells how often an action happens (e.g., *always*, *sometimes*, *rarely*, *never*).'],
            ['front' => 'What is a **Proper Noun**?', 'back' => 'A specific name for a person, place, or organization, always capitalized (e.g., *Paris*, *Shakespeare*).'],
            ['front' => 'What is a **Common Noun**?', 'back' => 'A generic name for a person, place, or thing (e.g., *city*, *writer*, *table*).'],
            ['front' => 'What is a **Countable Noun**?', 'back' => 'A noun that can be counted and has a plural form (e.g., *three books*, *two apples*).'],
            ['front' => 'What is an **Uncountable Noun**?', 'back' => 'A substance, concept, or quality that cannot be counted (e.g., *water*, *advice*, *information*).'],
            ['front' => 'What is a **Transitive Verb**?', 'back' => 'A verb requiring a direct object to complete its meaning (e.g., *She brought an umbrella*).'],
            ['front' => 'What is an **Intransitive Verb**?', 'back' => 'A verb that does not require an object (e.g., *The baby cried loudly*).'],
            ['front' => 'What is an **Imperative Sentence**?', 'back' => 'A sentence giving an instruction, advice, or command (e.g., *Please close the window*).'],
            ['front' => 'What is an **Exclamatory Sentence**?', 'back' => 'A sentence expressing strong surprise, anger, or joy (e.g., *How incredible this is!*).'],
            ['front' => 'What is an **Interrogative Sentence**?', 'back' => 'A sentence asking a question (e.g., *Where is the nearest library?*).'],
            ['front' => 'What is a **Declarative Sentence**?', 'back' => 'A sentence stating a fact, argument, or idea (e.g., *The earth orbits the sun*).'],
            ['front' => 'What is **Active Voice**?', 'back' => 'The subject performs the action stated by the verb (e.g., *The cat caught the mouse*).'],
            ['front' => 'What is **Passive Voice**?', 'back' => 'The subject receives the action of the verb (e.g., *The mouse was caught by the cat*).'],
            ['front' => 'What is a **Clause**?', 'back' => 'A group of words containing a subject and a predicate (e.g., *when the bell rang*).'],
            ['front' => 'What is a **Phrase**?', 'back' => 'A group of words without a subject-verb unit (e.g., *in the morning*, *under the tree*).'],
            ['front' => 'What is a **Complex Sentence**?', 'back' => 'A sentence containing one independent clause and at least one dependent clause.'],
            ['front' => 'What is a **Compound Sentence**?', 'back' => 'A sentence joining two independent clauses with a conjunction (e.g., *I ran fast, but I missed it*).'],
            ['front' => 'What is the Oxford Comma?', 'back' => 'A comma placed immediately before the coordinating conjunction in a list (e.g., *apples, bananas, and cherries*).']
        ];

        $activities = [
            [
                'title' => 'MCQ',
                'type' => 'mcq',
                'data_json' => [
                    'title' => 'MCQ Grammar & Vocab Arena',
                    'question' => 'Choose the correct answer for each language challenge:',
                    'options' => $mcqPool[0]['options'],
                    'questions' => $mcqPool
                ]
            ],
            [
                'title' => 'Match',
                'type' => 'match',
                'data_json' => [
                    'title' => 'Match Pairs',
                    'question' => 'Match corresponding words and definitions:',
                    'theme' => 'cloud',
                    'pairs' => $matchPairs
                ]
            ],
            [
                'title' => 'Word Arrange',
                'type' => 'word_arrange',
                'data_json' => [
                    'title' => 'Word Arrange',
                    'question' => 'Unscramble the words to make a correct sentence:',
                    'text' => 'The majestic birds are singing merrily in the sunny garden.'
                ]
            ],
            [
                'title' => 'Fill in the Blanks',
                'type' => 'fill_blanks',
                'data_json' => [
                    'title' => 'Fill in the Blanks',
                    'question' => 'Fill in the correct words to complete the sentence:',
                    'text' => 'The sun [rises] (rises / sets) in the east and sets in the [west] (north / west).',
                    'sentences' => $fillBlanksPool
                ]
            ],
            [
                'title' => 'Flashcard',
                'type' => 'flashcard',
                'data_json' => [
                    'title' => 'Vocabulary Flashcard Deck',
                    'front' => 'What is an **Adjective**?',
                    'back' => 'An adjective describes or modifies a noun (e.g., *happy*, *clever*, *bright*, *resilient*).',
                    'cards' => $flashcardPool
                ]
            ],
            [
                'title' => 'Word Ninja',
                'type' => 'word_ninja',
                'data_json' => [
                    'title' => 'Word Ninja: Katana Dojo',
                    'prompt' => 'Slice only ADJECTIVES!',
                    'correctWords' => [
                        'Beautiful', 'Quick', 'Bright', 'Clever', 'Happy', 'Gentle', 'Fierce', 'Silent',
                        'Enormous', 'Brilliant', 'Valiant', 'Radiant', 'Tenacious', 'Lucid', 'Resilient',
                        'Pristine', 'Audacious', 'Candid', 'Diligent', 'Eloquent', 'Benevolent', 'Tranquil',
                        'Meticulous', 'Vibrant', 'Gleeful', 'Magnanimous', 'Serene', 'Affable', 'Pensive',
                        'Resolute', 'Sagacious', 'Swift', 'Fragile', 'Courageous', 'Miniature', 'Furious',
                        'Exhausted', 'Opaque', 'Genuine', 'Abundant', 'Cautious', 'Humble', 'Perilous',
                        'Vivid', 'Peculiar', 'Gargantuan', 'Affluent', 'Luminous', 'Kinetic', 'Graceful'
                    ],
                    'wrongWords' => [
                        'Run', 'Cat', 'Eat', 'Table', 'Jump', 'Castle', 'Building', 'Elephant', 'Tree', 'Sleep',
                        'Guitar', 'Window', 'Chair', 'Bottle', 'Desk', 'Pencil', 'Computer', 'Folder', 'Drive',
                        'Sing', 'Swim', 'Fly', 'Walk', 'Climb', 'Roar', 'Dance', 'Sprint', 'Whistle', 'Simmer',
                        'Bake', 'Sauté', 'Galaxy', 'Nebula', 'Comet', 'Hexagon', 'Octagon', 'Rhombus', 'Submarine',
                        'Helicopter', 'Airplane', 'Violin', 'Trumpet', 'Clarinet', 'Flute', 'Heart', 'Lungs',
                        'Kidneys', 'Liver', 'Stomach', 'Brain'
                    ]
                ]
            ],
            [
                'title' => 'Car Racer',
                'type' => 'car_racer',
                'data_json' => [
                    'title' => '3-Lane Highway Racer',
                    'question' => 'Steer car into the correct lane!',
                    'rounds' => $racerRounds
                ]
            ],
            [
                'title' => 'Flappy Word',
                'type' => 'flappy_word',
                'data_json' => [
                    'title' => 'Flappy Word Skyways',
                    'question' => 'Fly through the correct word cloud gates:',
                    'gates' => $flappyGates
                ]
            ],
            [
                'title' => 'Balloon Pop',
                'type' => 'balloon_pop',
                'data_json' => [
                    'title' => 'Balloon Word Pop Fiesta',
                    'targetCategory' => 'Adjectives',
                    'correctWords' => [
                        'Golden', 'Swift', 'Bright', 'Clever', 'Gentle', 'Silent', 'Enormous', 'Brave',
                        'Shiny', 'Spicy', 'Fluffy', 'Crispy', 'Valiant', 'Radiant', 'Tenacious', 'Lucid',
                        'Resilient', 'Pristine', 'Audacious', 'Candid', 'Diligent', 'Eloquent', 'Benevolent',
                        'Tranquil', 'Meticulous', 'Vibrant', 'Gleeful', 'Magnanimous', 'Serene', 'Affable',
                        'Pensive', 'Resolute', 'Sagacious', 'Fragile', 'Courageous', 'Miniature', 'Furious',
                        'Exhausted', 'Opaque', 'Genuine', 'Abundant', 'Cautious', 'Humble', 'Perilous',
                        'Vivid', 'Peculiar', 'Gargantuan', 'Affluent', 'Luminous', 'Kinetic'
                    ],
                    'wrongWords' => [
                        'Table', 'Water', 'Computer', 'Bottle', 'Bridge', 'Pencil', 'Chair', 'Castle',
                        'Door', 'Clock', 'Cup', 'Road', 'Lamp', 'Box', 'Fork', 'Desk', 'Iron', 'Glass',
                        'Wire', 'Train', 'Bike', 'Spoon', 'Key', 'Ruler', 'Hammer', 'Wrench', 'Screwdriver',
                        'Saw', 'Drill', 'Carrot', 'Potato', 'Turnip', 'Radish', 'Ginger', 'Sofa', 'Toaster',
                        'Refrigerator', 'Microwave', 'Blender', 'Subway', 'Helicopter', 'Airplane', 'Truck',
                        'Scooter', 'Pebble', 'Gravel', 'Mud', 'Clay', 'Sandstone', 'Pavement'
                    ]
                ]
            ],
            [
                'title' => 'Space Defender',
                'type' => 'space_defender',
                'data_json' => [
                    'title' => 'Space Defender',
                    'challenges' => [
                        ['target' => 'Planet', 'distractors' => ['Chair', 'Shoe', 'Door']],
                        ['target' => 'Rocket', 'distractors' => ['Spoon', 'Book', 'Pencil']],
                        ['target' => 'Galaxy', 'distractors' => ['Table', 'Fork', 'Bed']],
                        ['target' => 'Asteroid', 'distractors' => ['Apple', 'Cat', 'Car']],
                        ['target' => 'Cosmos', 'distractors' => ['Sock', 'Cup', 'Hat']]
                    ]
                ]
            ],
            [
                'title' => 'Crossword',
                'type' => 'crossword',
                'data_json' => [
                    'title' => 'Crossword Vocabulary Grid',
                    'gridSize' => 8,
                    'words' => [
                        ['word' => 'SUN', 'clue' => 'Star at center of solar system', 'row' => 1, 'col' => 1, 'direction' => 'across'],
                        ['word' => 'SEA', 'clue' => 'Large body of saltwater', 'row' => 1, 'col' => 1, 'direction' => 'down'],
                        ['word' => 'AIR', 'clue' => 'Invisible gas we breathe', 'row' => 3, 'col' => 1, 'direction' => 'across'],
                        ['word' => 'RAIN', 'clue' => 'Water drops falling from clouds', 'row' => 1, 'col' => 3, 'direction' => 'down']
                    ]
                ]
            ],
            [
                'title' => 'Writing',
                'type' => 'writing',
                'data_json' => [
                    'title' => 'Writing',
                    'question' => 'Look at the pictures and write the correct words:',
                    'mode' => 'image_fill',
                    'pairs' => [
                        [
                            'leftImage' => 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=150&q=80',
                            'leftAnswer' => 'dog',
                            'rightImage' => 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=150&q=80',
                            'rightAnswer' => 'cat'
                        ]
                    ]
                ]
            ]
        ];

        foreach ($activities as $act) {
            Activity::updateOrCreate(
                ['title' => $act['title'], 'tenant_id' => null],
                [
                    'type' => $act['type'],
                    'course_id' => $courseId,
                    'data_json' => $act['data_json'],
                    'created_by' => null
                ]
            );
        }
    }
}
