<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Activity;
use App\Models\Course;

class ActivitySeeder extends Seeder
{
    public function run(): void
    {
        $course = Course::first();
        $courseId = $course ? $course->id : null;

        // 1. 🧩 5 DYNAMIC MATCH IT ACTIVITIES
        $matchActivities = [
            [
                'title' => 'Set 1: Everyday Greetings & Manners',
                'type' => 'match',
                'course_id' => $courseId,
                'data_json' => [
                    'theme' => 'standard',
                    'allowClickMatch' => true,
                    'allowDragDrop' => true,
                    'explanation' => 'Match basic greetings with their polite meanings.',
                    'pairs' => [
                        ['left' => 'Hello / Hi', 'right' => 'வணக்கம் (Vanakkam)', 'rightImage' => ''],
                        ['left' => 'Good morning', 'right' => 'காலை வணக்கம் (Kaalai Vanakkam)', 'rightImage' => ''],
                        ['left' => 'Thank you', 'right' => 'நன்றி (Nandri)', 'rightImage' => ''],
                        ['left' => 'Please', 'right' => 'தயவுசெய்து (Thayavu Seithu)', 'rightImage' => ''],
                        ['left' => 'Goodbye', 'right' => 'சென்று வருகிறேன் (Sendru Varugiren)', 'rightImage' => '']
                    ]
                ]
            ],
            [
                'title' => 'Set 2: Food, Drinks & Dining',
                'type' => 'match',
                'course_id' => $courseId,
                'data_json' => [
                    'theme' => 'standard',
                    'allowClickMatch' => true,
                    'allowDragDrop' => true,
                    'explanation' => 'Match dining and food vocabulary.',
                    'pairs' => [
                        ['left' => 'Water', 'right' => 'தண்ணீர் (Thanneer)', 'rightImage' => ''],
                        ['left' => 'Bread', 'right' => 'ரொட்டி (Rotti)', 'rightImage' => ''],
                        ['left' => 'Apple', 'right' => 'ஆப்பிள் பழம் (Apple)', 'rightImage' => ''],
                        ['left' => 'Coffee', 'right' => 'காபி (Coffee)', 'rightImage' => ''],
                        ['left' => 'Milk', 'right' => 'பால் (Paal)', 'rightImage' => '']
                    ]
                ]
            ],
            [
                'title' => 'Set 3: Family, People & Relations',
                'type' => 'match',
                'course_id' => $courseId,
                'data_json' => [
                    'theme' => 'standard',
                    'allowClickMatch' => true,
                    'allowDragDrop' => true,
                    'explanation' => 'Match family member terms with meanings.',
                    'pairs' => [
                        ['left' => 'Father', 'right' => 'அப்பா (Appa)', 'rightImage' => ''],
                        ['left' => 'Mother', 'right' => 'அம்மா (Amma)', 'rightImage' => ''],
                        ['left' => 'Brother', 'right' => 'சகோதரன் (Sagodharan)', 'rightImage' => ''],
                        ['left' => 'Sister', 'right' => 'சகோதரி (Sagodhari)', 'rightImage' => ''],
                        ['left' => 'Friend', 'right' => 'நண்பர் (Nanbar)', 'rightImage' => '']
                    ]
                ]
            ],
            [
                'title' => 'Set 4: Colors, Nature & Environment',
                'type' => 'match',
                'course_id' => $courseId,
                'data_json' => [
                    'theme' => 'standard',
                    'allowClickMatch' => true,
                    'allowDragDrop' => true,
                    'explanation' => 'Match colors and elements of nature.',
                    'pairs' => [
                        ['left' => 'Red', 'right' => 'சிவப்பு (Sivappu)', 'rightImage' => ''],
                        ['left' => 'Blue', 'right' => 'நீலம் (Neelam)', 'rightImage' => ''],
                        ['left' => 'Green', 'right' => 'பச்சை (Pachai)', 'rightImage' => ''],
                        ['left' => 'Sun', 'right' => 'சூரியன் (Sooriyan)', 'rightImage' => ''],
                        ['left' => 'Moon', 'right' => 'நிலா (Nila)', 'rightImage' => '']
                    ]
                ]
            ],
            [
                'title' => 'Set 5: Everyday Actions & Common Verbs',
                'type' => 'match',
                'course_id' => $courseId,
                'data_json' => [
                    'theme' => 'standard',
                    'allowClickMatch' => true,
                    'allowDragDrop' => true,
                    'explanation' => 'Match common everyday active verbs.',
                    'pairs' => [
                        ['left' => 'To eat', 'right' => 'சாப்பிடு (Saapidu)', 'rightImage' => ''],
                        ['left' => 'To drink', 'right' => 'குடி (Kudi)', 'rightImage' => ''],
                        ['left' => 'To speak', 'right' => 'பேசு (Pesu)', 'rightImage' => ''],
                        ['left' => 'To read', 'right' => 'படி (Padi)', 'rightImage' => ''],
                        ['left' => 'To sleep', 'right' => 'தூங்கு (Thoongu)', 'rightImage' => '']
                    ]
                ]
            ]
        ];

        // 2. ✍️ 5 DYNAMIC FILL IN THE BLANKS ACTIVITIES
        $fillBlankActivities = [
            [
                'title' => 'Fill Up 1: Polite Morning Greeting',
                'type' => 'fill_blanks',
                'course_id' => $courseId,
                'data_json' => [
                    'text' => 'Good [Morning|Water|Sleep|Table]! How was your weekend?',
                    'prompt' => 'Good _____! How was your weekend?',
                    'options' => ['Morning', 'Water', 'Sleep', 'Table'],
                    'correctIndex' => 0,
                    'explanation' => '"Good morning" is the polite morning greeting.'
                ]
            ],
            [
                'title' => 'Fill Up 2: Restaurant & Cafe Request',
                'type' => 'fill_blanks',
                'course_id' => $courseId,
                'data_json' => [
                    'text' => 'Could you please [bring|run|sing|jump] me a cup of tea?',
                    'prompt' => 'Could you please _____ me a cup of tea?',
                    'options' => ['bring', 'run', 'sing', 'jump'],
                    'correctIndex' => 0,
                    'explanation' => '"bring" is the correct verb for requesting an item.'
                ]
            ],
            [
                'title' => 'Fill Up 3: Learning Journey Dialogue',
                'type' => 'fill_blanks',
                'course_id' => $courseId,
                'data_json' => [
                    'text' => 'I am practicing a new [language|sandwich|chair|cloud] with LangNest today.',
                    'prompt' => 'I am practicing a new _____ with LangNest today.',
                    'options' => ['language', 'sandwich', 'chair', 'cloud'],
                    'correctIndex' => 0,
                    'explanation' => '"language" is the correct noun for what you study in LangNest.'
                ]
            ],
            [
                'title' => 'Fill Up 4: Conversation Fluency',
                'type' => 'fill_blanks',
                'course_id' => $courseId,
                'data_json' => [
                    'text' => 'She speaks conversational English very [fluently|blue|yesterday|quiet].',
                    'prompt' => 'She speaks conversational English very _____.',
                    'options' => ['fluently', 'blue', 'yesterday', 'quiet'],
                    'correctIndex' => 0,
                    'explanation' => '"fluently" is the adverb describing smooth speaking.'
                ]
            ],
            [
                'title' => 'Fill Up 5: Heartfelt Gratitude',
                'type' => 'fill_blanks',
                'course_id' => $courseId,
                'data_json' => [
                    'text' => 'Thank you [so|how|when|under] much for your helpful assistance.',
                    'prompt' => 'Thank you _____ much for your helpful assistance.',
                    'options' => ['so', 'how', 'when', 'under'],
                    'correctIndex' => 0,
                    'explanation' => '"so much" is the common intensifying phrase for gratitude.'
                ]
            ]
        ];

        // 3. 🗂️ 5 DYNAMIC FLASHCARDS
        $flashcardActivities = [
            [
                'title' => 'Flashcard: Buenos Días',
                'type' => 'flashcard',
                'course_id' => $courseId,
                'data_json' => [
                    'front' => 'Buenos Días',
                    'frontLanguage' => 'Spanish',
                    'back' => 'Good Morning!',
                    'backLanguage' => 'English',
                    'pronunciation' => '[bwe-nos dee-as]'
                ]
            ],
            [
                'title' => 'Flashcard: Por Favor',
                'type' => 'flashcard',
                'course_id' => $courseId,
                'data_json' => [
                    'front' => 'Por favor',
                    'frontLanguage' => 'Spanish',
                    'back' => 'Please',
                    'backLanguage' => 'English',
                    'pronunciation' => '[por fah-vor]'
                ]
            ],
            [
                'title' => 'Flashcard: Muchas Gracias',
                'type' => 'flashcard',
                'course_id' => $courseId,
                'data_json' => [
                    'front' => 'Muchas Gracias',
                    'frontLanguage' => 'Spanish',
                    'back' => 'Thank You Very Much!',
                    'backLanguage' => 'English',
                    'pronunciation' => '[moo-chas grah-syahs]'
                ]
            ],
            [
                'title' => 'Flashcard: ¿Cómo estás?',
                'type' => 'flashcard',
                'course_id' => $courseId,
                'data_json' => [
                    'front' => '¿Cómo estás?',
                    'frontLanguage' => 'Spanish',
                    'back' => 'How are you?',
                    'backLanguage' => 'English',
                    'pronunciation' => '[koh-moh eh-stahs]'
                ]
            ],
            [
                'title' => 'Flashcard: Hasta luego',
                'type' => 'flashcard',
                'course_id' => $courseId,
                'data_json' => [
                    'front' => 'Hasta luego',
                    'frontLanguage' => 'Spanish',
                    'back' => 'See you later / Goodbye!',
                    'backLanguage' => 'English',
                    'pronunciation' => '[ahs-tah lweh-goh]'
                ]
            ]
        ];

        // 4. ⚡ 5 DYNAMIC MCQ QUESTIONS
        $mcqActivities = [
            [
                'title' => 'Quiz: Spanish Greeting "Hello"',
                'type' => 'mcq',
                'course_id' => $courseId,
                'data_json' => [
                    'question' => 'What is the Spanish word for "Hello"?',
                    'options' => [
                        ['text' => 'Hola', 'isCorrect' => true],
                        ['text' => 'Adiós', 'isCorrect' => false],
                        ['text' => 'Gracias', 'isCorrect' => false],
                        ['text' => 'Por favor', 'isCorrect' => false]
                    ]
                ]
            ],
            [
                'title' => 'Quiz: French Expression "Thank You"',
                'type' => 'mcq',
                'course_id' => $courseId,
                'data_json' => [
                    'question' => 'Which of the following means "Thank You" in French?',
                    'options' => [
                        ['text' => 'Bonjour', 'isCorrect' => false],
                        ['text' => 'Merci', 'isCorrect' => true],
                        ['text' => 'S\'il vous plaît', 'isCorrect' => false],
                        ['text' => 'Oui', 'isCorrect' => false]
                    ]
                ]
            ],
            [
                'title' => 'Quiz: German Greeting "Good Morning"',
                'type' => 'mcq',
                'course_id' => $courseId,
                'data_json' => [
                    'question' => 'How do you say "Good Morning" in German?',
                    'options' => [
                        ['text' => 'Guten Tag', 'isCorrect' => false],
                        ['text' => 'Gute Nacht', 'isCorrect' => false],
                        ['text' => 'Guten Morgen', 'isCorrect' => true],
                        ['text' => 'Tschüss', 'isCorrect' => false]
                    ]
                ]
            ],
            [
                'title' => 'Quiz: Spanish Word for "Water"',
                'type' => 'mcq',
                'course_id' => $courseId,
                'data_json' => [
                    'question' => 'What is the Spanish word for "Water"?',
                    'options' => [
                        ['text' => 'Fuego', 'isCorrect' => false],
                        ['text' => 'Agua', 'isCorrect' => true],
                        ['text' => 'Tierra', 'isCorrect' => false],
                        ['text' => 'Viento', 'isCorrect' => false]
                    ]
                ]
            ],
            [
                'title' => 'Quiz: Polite Word for "Please" in Spanish',
                'type' => 'mcq',
                'course_id' => $courseId,
                'data_json' => [
                    'question' => 'Which word expresses "Please" in Spanish?',
                    'options' => [
                        ['text' => 'De nada', 'isCorrect' => false],
                        ['text' => 'Por favor', 'isCorrect' => true],
                        ['text' => 'Perdón', 'isCorrect' => false],
                        ['text' => 'Hasta pronto', 'isCorrect' => false]
                    ]
                ]
            ]
        ];

        // 5. 🔤 5 DYNAMIC WORD SCRAMBLE / SENTENCE BUILDER ACTIVITIES
        $wordArrangeActivities = [
            [
                'title' => 'Word Scramble: Daily Learning Routine',
                'type' => 'word_arrange',
                'course_id' => $courseId,
                'data_json' => [
                    'englishMeaning' => 'I want to learn English every day.',
                    'targetText' => 'I want to learn English every day',
                    'sentenceWords' => ['I', 'want', 'to', 'learn', 'English', 'every', 'day'],
                    'correctSentence' => 'I want to learn English every day'
                ]
            ],
            [
                'title' => 'Word Scramble: Asking for Train Station',
                'type' => 'word_arrange',
                'course_id' => $courseId,
                'data_json' => [
                    'englishMeaning' => 'Where is the nearest train station?',
                    'targetText' => 'Where is the nearest train station?',
                    'sentenceWords' => ['Where', 'is', 'the', 'nearest', 'train', 'station?'],
                    'correctSentence' => 'Where is the nearest train station?'
                ]
            ],
            [
                'title' => 'Word Scramble: Asking for Polite Help',
                'type' => 'word_arrange',
                'course_id' => $courseId,
                'data_json' => [
                    'englishMeaning' => 'Can you help me please?',
                    'targetText' => 'Can you help me please?',
                    'sentenceWords' => ['Can', 'you', 'help', 'me', 'please?'],
                    'correctSentence' => 'Can you help me please?'
                ]
            ],
            [
                'title' => 'Word Scramble: Praising Coffee',
                'type' => 'word_arrange',
                'course_id' => $courseId,
                'data_json' => [
                    'englishMeaning' => 'This coffee is very delicious.',
                    'targetText' => 'This coffee is very delicious',
                    'sentenceWords' => ['This', 'coffee', 'is', 'very', 'delicious'],
                    'correctSentence' => 'This coffee is very delicious'
                ]
            ],
            [
                'title' => 'Word Scramble: Wishing a Happy Day',
                'type' => 'word_arrange',
                'course_id' => $courseId,
                'data_json' => [
                    'englishMeaning' => 'Have a wonderful and happy day.',
                    'targetText' => 'Have a wonderful and happy day',
                    'sentenceWords' => ['Have', 'a', 'wonderful', 'and', 'happy', 'day'],
                    'correctSentence' => 'Have a wonderful and happy day'
                ]
            ]
        ];

        // Seed all into database
        $all = array_merge(
            $matchActivities,
            $fillBlankActivities,
            $flashcardActivities,
            $mcqActivities,
            $wordArrangeActivities
        );

        foreach ($all as $item) {
            Activity::updateOrCreate(
                ['title' => $item['title']],
                [
                    'type' => $item['type'],
                    'course_id' => $item['course_id'],
                    'data_json' => $item['data_json'],
                    'tenant_id' => null,
                    'created_by' => null,
                ]
            );
        }
    }
}
