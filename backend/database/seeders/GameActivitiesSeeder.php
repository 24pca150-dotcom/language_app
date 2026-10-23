<?php

namespace Database\Seeders;

use App\Models\Activity;
use Illuminate\Database\Seeder;

class GameActivitiesSeeder extends Seeder
{
    public function run(): void
    {
        $activities = [
            // ==========================================
            // 1. 🏎️ 3-LANE HIGHWAY RACER (CAR GAME)
            // ==========================================
            [
                'title' => '🏎️ Highway Racer: Irregular Past Tense',
                'type' => 'car_racer',
                'course_id' => null,
                'data_json' => [
                    'title' => '🏎️ Highway Racer: Irregular Past Tense',
                    'speed' => 'normal',
                    'rounds' => [
                        [
                            'question' => 'Steer to the Past Tense of "Drive":',
                            'options' => [
                                ['text' => 'Drove', 'isCorrect' => true],
                                ['text' => 'Drived', 'isCorrect' => false],
                                ['text' => 'Driven', 'isCorrect' => false],
                            ]
                        ],
                        [
                            'question' => 'Steer to the Past Tense of "Eat":',
                            'options' => [
                                ['text' => 'Eaten', 'isCorrect' => false],
                                ['text' => 'Ate', 'isCorrect' => true],
                                ['text' => 'Eated', 'isCorrect' => false],
                            ]
                        ],
                        [
                            'question' => 'Steer to the Past Tense of "Fly":',
                            'options' => [
                                ['text' => 'Flew', 'isCorrect' => true],
                                ['text' => 'Flied', 'isCorrect' => false],
                                ['text' => 'Flown', 'isCorrect' => false],
                            ]
                        ],
                        [
                            'question' => 'Steer to the Past Tense of "Catch":',
                            'options' => [
                                ['text' => 'Catched', 'isCorrect' => false],
                                ['text' => 'Caught', 'isCorrect' => true],
                                ['text' => 'Caughter', 'isCorrect' => false],
                            ]
                        ],
                        [
                            'question' => 'Steer to the Past Tense of "Write":',
                            'options' => [
                                ['text' => 'Written', 'isCorrect' => false],
                                ['text' => 'Writed', 'isCorrect' => false],
                                ['text' => 'Wrote', 'isCorrect' => true],
                            ]
                        ],
                    ]
                ]
            ],
            [
                'title' => '🏎️ Highway Racer: Plural Nouns Speedway',
                'type' => 'car_racer',
                'course_id' => null,
                'data_json' => [
                    'title' => '🏎️ Highway Racer: Plural Nouns Speedway',
                    'speed' => 'normal',
                    'rounds' => [
                        [
                            'question' => 'Pick the correct Plural of "Child":',
                            'options' => [
                                ['text' => 'Children', 'isCorrect' => true],
                                ['text' => 'Childs', 'isCorrect' => false],
                                ['text' => 'Childes', 'isCorrect' => false],
                            ]
                        ],
                        [
                            'question' => 'Pick the correct Plural of "Mouse":',
                            'options' => [
                                ['text' => 'Mouses', 'isCorrect' => false],
                                ['text' => 'Mice', 'isCorrect' => true],
                                ['text' => 'Meese', 'isCorrect' => false],
                            ]
                        ],
                        [
                            'question' => 'Pick the correct Plural of "Tooth":',
                            'options' => [
                                ['text' => 'Tooths', 'isCorrect' => false],
                                ['text' => 'Teeth', 'isCorrect' => true],
                                ['text' => 'Teethes', 'isCorrect' => false],
                            ]
                        ],
                        [
                            'question' => 'Pick the correct Plural of "Cactus":',
                            'options' => [
                                ['text' => 'Cactuses', 'isCorrect' => false],
                                ['text' => 'Cacti', 'isCorrect' => true],
                                ['text' => 'Cactii', 'isCorrect' => false],
                            ]
                        ],
                        [
                            'question' => 'Pick the correct Plural of "Knife":',
                            'options' => [
                                ['text' => 'Knifes', 'isCorrect' => false],
                                ['text' => 'Knives', 'isCorrect' => true],
                                ['text' => 'Kniefs', 'isCorrect' => false],
                            ]
                        ],
                    ]
                ]
            ],
            [
                'title' => '🏎️ Highway Racer: Antonym Rush',
                'type' => 'car_racer',
                'course_id' => null,
                'data_json' => [
                    'title' => '🏎️ Highway Racer: Antonym Rush',
                    'speed' => 'fast',
                    'rounds' => [
                        [
                            'question' => 'Opposite of "Ancient":',
                            'options' => [
                                ['text' => 'Modern', 'isCorrect' => true],
                                ['text' => 'Old', 'isCorrect' => false],
                                ['text' => 'Classic', 'isCorrect' => false],
                            ]
                        ],
                        [
                            'question' => 'Opposite of "Generous":',
                            'options' => [
                                ['text' => 'Kind', 'isCorrect' => false],
                                ['text' => 'Stingy', 'isCorrect' => true],
                                ['text' => 'Helpful', 'isCorrect' => false],
                            ]
                        ],
                        [
                            'question' => 'Opposite of "Expand":',
                            'options' => [
                                ['text' => 'Contract', 'isCorrect' => true],
                                ['text' => 'Enlarge', 'isCorrect' => false],
                                ['text' => 'Spread', 'isCorrect' => false],
                            ]
                        ],
                        [
                            'question' => 'Opposite of "Victory":',
                            'options' => [
                                ['text' => 'Success', 'isCorrect' => false],
                                ['text' => 'Defeat', 'isCorrect' => true],
                                ['text' => 'Triumph', 'isCorrect' => false],
                            ]
                        ],
                        [
                            'question' => 'Opposite of "Permanent":',
                            'options' => [
                                ['text' => 'Lasting', 'isCorrect' => false],
                                ['text' => 'Temporary', 'isCorrect' => true],
                                ['text' => 'Constant', 'isCorrect' => false],
                            ]
                        ],
                    ]
                ]
            ],
            [
                'title' => '🏎️ Highway Racer: Comparative & Superlative',
                'type' => 'car_racer',
                'course_id' => null,
                'data_json' => [
                    'title' => '🏎️ Highway Racer: Comparative & Superlative',
                    'speed' => 'normal',
                    'rounds' => [
                        [
                            'question' => 'Superlative of "Good":',
                            'options' => [
                                ['text' => 'Better', 'isCorrect' => false],
                                ['text' => 'Best', 'isCorrect' => true],
                                ['text' => 'Goodest', 'isCorrect' => false],
                            ]
                        ],
                        [
                            'question' => 'Comparative of "Bad":',
                            'options' => [
                                ['text' => 'Worse', 'isCorrect' => true],
                                ['text' => 'Worst', 'isCorrect' => false],
                                ['text' => 'Badder', 'isCorrect' => false],
                            ]
                        ],
                        [
                            'question' => 'Comparative of "Far":',
                            'options' => [
                                ['text' => 'Further', 'isCorrect' => true],
                                ['text' => 'Farest', 'isCorrect' => false],
                                ['text' => 'Most Far', 'isCorrect' => false],
                            ]
                        ],
                        [
                            'question' => 'Superlative of "Little":',
                            'options' => [
                                ['text' => 'Littlest', 'isCorrect' => false],
                                ['text' => 'Least', 'isCorrect' => true],
                                ['text' => 'Less', 'isCorrect' => false],
                            ]
                        ],
                        [
                            'question' => 'Comparative of "Busy":',
                            'options' => [
                                ['text' => 'Busier', 'isCorrect' => true],
                                ['text' => 'More Busy', 'isCorrect' => false],
                                ['text' => 'Busiest', 'isCorrect' => false],
                            ]
                        ],
                    ]
                ]
            ],
            [
                'title' => '🏎️ Highway Racer: Preposition Track',
                'type' => 'car_racer',
                'course_id' => null,
                'data_json' => [
                    'title' => '🏎️ Highway Racer: Preposition Track',
                    'speed' => 'normal',
                    'rounds' => [
                        [
                            'question' => 'He arrived ___ Monday morning:',
                            'options' => [
                                ['text' => 'on', 'isCorrect' => true],
                                ['text' => 'in', 'isCorrect' => false],
                                ['text' => 'at', 'isCorrect' => false],
                            ]
                        ],
                        [
                            'question' => 'The plane lands ___ 6:30 PM:',
                            'options' => [
                                ['text' => 'in', 'isCorrect' => false],
                                ['text' => 'at', 'isCorrect' => true],
                                ['text' => 'on', 'isCorrect' => false],
                            ]
                        ],
                        [
                            'question' => 'We will travel ___ December:',
                            'options' => [
                                ['text' => 'in', 'isCorrect' => true],
                                ['text' => 'at', 'isCorrect' => false],
                                ['text' => 'on', 'isCorrect' => false],
                            ]
                        ],
                        [
                            'question' => 'The cat is hiding ___ the table:',
                            'options' => [
                                ['text' => 'under', 'isCorrect' => true],
                                ['text' => 'between', 'isCorrect' => false],
                                ['text' => 'among', 'isCorrect' => false],
                            ]
                        ],
                        [
                            'question' => 'She walked ___ the dark tunnel:',
                            'options' => [
                                ['text' => 'through', 'isCorrect' => true],
                                ['text' => 'across', 'isCorrect' => false],
                                ['text' => 'over', 'isCorrect' => false],
                            ]
                        ],
                    ]
                ]
            ],

            // ==========================================
            // 2. ⚔️ WORD NINJA (WORD SLICER GAME)
            // ==========================================
            [
                'title' => '⚔️ Word Ninja: Slice All Adjectives',
                'type' => 'word_ninja',
                'course_id' => null,
                'data_json' => [
                    'title' => '⚔️ Word Ninja: Slice All Adjectives',
                    'question' => 'Slice only descriptive Adjectives!',
                    'correctWords' => ['Brave', 'Sparkling', 'Gentle', 'Luminous', 'Fierce', 'Cozy', 'Silent', 'Vibrant'],
                    'wrongWords' => ['Run', 'Carefully', 'Table', 'Jump', 'Quickly', 'Building', 'Sing'],
                    'speed' => 'normal'
                ]
            ],
            [
                'title' => '⚔️ Word Ninja: Action Verbs Slash',
                'type' => 'word_ninja',
                'course_id' => null,
                'data_json' => [
                    'title' => '⚔️ Word Ninja: Action Verbs Slash',
                    'question' => 'Slice the Action Verbs!',
                    'correctWords' => ['Sprint', 'Climb', 'Whisper', 'Explore', 'Devour', 'Leap', 'Create', 'Shatter'],
                    'wrongWords' => ['Apple', 'Happiness', 'Blue', 'Heavy', 'Elephant', 'Quiet', 'Window'],
                    'speed' => 'normal'
                ]
            ],
            [
                'title' => '⚔️ Word Ninja: Positive Emotion Synonyms',
                'type' => 'word_ninja',
                'course_id' => null,
                'data_json' => [
                    'title' => '⚔️ Word Ninja: Positive Emotion Synonyms',
                    'question' => 'Slice Synonyms of "Happy" & "Joyful"!',
                    'correctWords' => ['Ecstatic', 'Thrilled', 'Delighted', 'Blissful', 'Cheerful', 'Elated', 'Gleeful'],
                    'wrongWords' => ['Gloomy', 'Furious', 'Bitter', 'Tired', 'Bored', 'Anxious', 'Envious'],
                    'speed' => 'normal'
                ]
            ],
            [
                'title' => '⚔️ Word Ninja: Professional Occupations',
                'type' => 'word_ninja',
                'course_id' => null,
                'data_json' => [
                    'title' => '⚔️ Word Ninja: Professional Occupations',
                    'question' => 'Slice words that are Careers and Professions!',
                    'correctWords' => ['Architect', 'Physician', 'Engineer', 'Journalist', 'Pilot', 'Surgeon', 'Chef'],
                    'wrongWords' => ['Office', 'Hospital', 'Kitchen', 'Airplane', 'Blueprint', 'Stethoscope'],
                    'speed' => 'normal'
                ]
            ],
            [
                'title' => '⚔️ Word Ninja: Adverbs of Manner',
                'type' => 'word_ninja',
                'course_id' => null,
                'data_json' => [
                    'title' => '⚔️ Word Ninja: Adverbs of Manner',
                    'question' => 'Slice the Adverbs of Manner!',
                    'correctWords' => ['Gracefully', 'Eagerly', 'Smoothly', 'Boldly', 'Patiently', 'Silently', 'Rapidly'],
                    'wrongWords' => ['Friendly', 'Lovely', 'Silly', 'Lonely', 'Ugly', 'Costly', 'Early'],
                    'speed' => 'normal'
                ]
            ],

            // ==========================================
            // 3. 🕊️ FLAPPY WORD (SKY FLIGHT GAME)
            // ==========================================
            [
                'title' => '🕊️ Flappy Word: Irregular Verb Skyways',
                'type' => 'flappy_word',
                'course_id' => null,
                'data_json' => [
                    'title' => '🕊️ Flappy Word: Irregular Verb Skyways',
                    'speed' => 'normal',
                    'waves' => [
                        [
                            'question' => 'Fly to the Past Tense of "Sing":',
                            'topOption' => ['text' => 'Sang', 'isCorrect' => true],
                            'bottomOption' => ['text' => 'Singed', 'isCorrect' => false]
                        ],
                        [
                            'question' => 'Fly to the Past Tense of "Freeze":',
                            'topOption' => ['text' => 'Frozed', 'isCorrect' => false],
                            'bottomOption' => ['text' => 'Froze', 'isCorrect' => true]
                        ],
                        [
                            'question' => 'Fly to the Past Tense of "Shake":',
                            'topOption' => ['text' => 'Shook', 'isCorrect' => true],
                            'bottomOption' => ['text' => 'Shaked', 'isCorrect' => false]
                        ],
                        [
                            'question' => 'Fly to the Past Tense of "Tear":',
                            'topOption' => ['text' => 'Teared', 'isCorrect' => false],
                            'bottomOption' => ['text' => 'Tore', 'isCorrect' => true]
                        ],
                        [
                            'question' => 'Fly to the Past Tense of "Bite":',
                            'topOption' => ['text' => 'Bit', 'isCorrect' => true],
                            'bottomOption' => ['text' => 'Bited', 'isCorrect' => false]
                        ]
                    ]
                ]
            ],
            [
                'title' => '🕊️ Flappy Word: Homophone Sky Navigation',
                'type' => 'flappy_word',
                'course_id' => null,
                'data_json' => [
                    'title' => '🕊️ Flappy Word: Homophone Sky Navigation',
                    'speed' => 'normal',
                    'waves' => [
                        [
                            'question' => 'The wind ___ the leaves away:',
                            'topOption' => ['text' => 'blue', 'isCorrect' => false],
                            'bottomOption' => ['text' => 'blew', 'isCorrect' => true]
                        ],
                        [
                            'question' => 'She wore a necklace of ___ beads:',
                            'topOption' => ['text' => 'plain', 'isCorrect' => true],
                            'bottomOption' => ['text' => 'plane', 'isCorrect' => false]
                        ],
                        [
                            'question' => 'I would like a ___ of chocolate cake:',
                            'topOption' => ['text' => 'piece', 'isCorrect' => true],
                            'bottomOption' => ['text' => 'peace', 'isCorrect' => false]
                        ],
                        [
                            'question' => "The king's long and prosperous ___ ended:",
                            'topOption' => ['text' => 'rain', 'isCorrect' => false],
                            'bottomOption' => ['text' => 'reign', 'isCorrect' => true]
                        ],
                        [
                            'question' => 'The knight polished his metal ___:',
                            'topOption' => ['text' => 'armor', 'isCorrect' => true],
                            'bottomOption' => ['text' => 'armer', 'isCorrect' => false]
                        ]
                    ]
                ]
            ],
            [
                'title' => '🕊️ Flappy Word: Prefix Power Flight',
                'type' => 'flappy_word',
                'course_id' => null,
                'data_json' => [
                    'title' => '🕊️ Flappy Word: Prefix Power Flight',
                    'speed' => 'normal',
                    'waves' => [
                        [
                            'question' => 'Prefix meaning "Not" or "Opposite":',
                            'topOption' => ['text' => 'Un-', 'isCorrect' => true],
                            'bottomOption' => ['text' => 'Re-', 'isCorrect' => false]
                        ],
                        [
                            'question' => 'Prefix meaning "Again":',
                            'topOption' => ['text' => 'Pre-', 'isCorrect' => false],
                            'bottomOption' => ['text' => 'Re-', 'isCorrect' => true]
                        ],
                        [
                            'question' => 'Prefix meaning "Before":',
                            'topOption' => ['text' => 'Pre-', 'isCorrect' => true],
                            'bottomOption' => ['text' => 'Post-', 'isCorrect' => false]
                        ],
                        [
                            'question' => 'Prefix meaning "Beneath" or "Under":',
                            'topOption' => ['text' => 'Super-', 'isCorrect' => false],
                            'bottomOption' => ['text' => 'Sub-', 'isCorrect' => true]
                        ],
                        [
                            'question' => 'Prefix meaning "Wrong" or "Badly":',
                            'topOption' => ['text' => 'Mis-', 'isCorrect' => true],
                            'bottomOption' => ['text' => 'Dis-', 'isCorrect' => false]
                        ]
                    ]
                ]
            ],
            [
                'title' => '🕊️ Flappy Word: Pronoun Agreement Flight',
                'type' => 'flappy_word',
                'course_id' => null,
                'data_json' => [
                    'title' => '🕊️ Flappy Word: Pronoun Agreement Flight',
                    'speed' => 'normal',
                    'waves' => [
                        [
                            'question' => 'Each student must bring ___ own book:',
                            'topOption' => ['text' => 'their', 'isCorrect' => true],
                            'bottomOption' => ['text' => "they're", 'isCorrect' => false]
                        ],
                        [
                            'question' => 'The dog wagged ___ tail happily:',
                            'topOption' => ['text' => "it's", 'isCorrect' => false],
                            'bottomOption' => ['text' => 'its', 'isCorrect' => true]
                        ],
                        [
                            'question' => 'Neither of the boys forgot ___ lunch:',
                            'topOption' => ['text' => 'his', 'isCorrect' => true],
                            'bottomOption' => ['text' => 'theirs', 'isCorrect' => false]
                        ],
                        [
                            'question' => 'The trophy belongs to Sarah and ___:',
                            'topOption' => ['text' => 'me', 'isCorrect' => true],
                            'bottomOption' => ['text' => 'I', 'isCorrect' => false]
                        ],
                        [
                            'question' => 'Between you and ___ this is a secret:',
                            'topOption' => ['text' => 'me', 'isCorrect' => true],
                            'bottomOption' => ['text' => 'I', 'isCorrect' => false]
                        ]
                    ]
                ]
            ],
            [
                'title' => '🕊️ Flappy Word: Common Idiom Gateways',
                'type' => 'flappy_word',
                'course_id' => null,
                'data_json' => [
                    'title' => '🕊️ Flappy Word: Common Idiom Gateways',
                    'speed' => 'normal',
                    'waves' => [
                        [
                            'question' => 'Finish idiom: "A piece of ___":',
                            'topOption' => ['text' => 'cake', 'isCorrect' => true],
                            'bottomOption' => ['text' => 'pie', 'isCorrect' => false]
                        ],
                        [
                            'question' => 'Finish idiom: "Break a ___" (Good luck):',
                            'topOption' => ['text' => 'bone', 'isCorrect' => false],
                            'bottomOption' => ['text' => 'leg', 'isCorrect' => true]
                        ],
                        [
                            'question' => 'Finish idiom: "Once in a blue ___":',
                            'topOption' => ['text' => 'moon', 'isCorrect' => true],
                            'bottomOption' => ['text' => 'star', 'isCorrect' => false]
                        ],
                        [
                            'question' => 'Finish idiom: "Spill the ___" (Reveal secret):',
                            'topOption' => ['text' => 'tea', 'isCorrect' => false],
                            'bottomOption' => ['text' => 'beans', 'isCorrect' => true]
                        ],
                        [
                            'question' => 'Finish idiom: "Bite the ___" (Face difficulty):',
                            'topOption' => ['text' => 'bullet', 'isCorrect' => true],
                            'bottomOption' => ['text' => 'lemon', 'isCorrect' => false]
                        ]
                    ]
                ]
            ],

            // ==========================================
            // 4. 🚀 SPACE WORD DEFENDER (GALAXY SHOOTER)
            // ==========================================
            [
                'title' => '🚀 Space Defender: Galaxy Antonym Blaster',
                'type' => 'space_defender',
                'course_id' => null,
                'data_json' => [
                    'title' => '🚀 Space Defender: Galaxy Antonym Blaster',
                    'speed' => 'normal',
                    'challenges' => [
                        [
                            'question' => 'Shoot the Antonym of "Cowardly":',
                            'targetWord' => 'Brave',
                            'distractors' => ['Timid', 'Fearful']
                        ],
                        [
                            'question' => 'Shoot the Antonym of "Humble":',
                            'targetWord' => 'Arrogant',
                            'distractors' => ['Modest', 'Polite']
                        ],
                        [
                            'question' => 'Shoot the Antonym of "Abundant":',
                            'targetWord' => 'Scarce',
                            'distractors' => ['Plentiful', 'Ample']
                        ],
                        [
                            'question' => 'Shoot the Antonym of "Candid":',
                            'targetWord' => 'Deceitful',
                            'distractors' => ['Honest', 'Direct']
                        ],
                        [
                            'question' => 'Shoot the Antonym of "Cautious":',
                            'targetWord' => 'Reckless',
                            'distractors' => ['Careful', 'Watchful']
                        ]
                    ]
                ]
            ],
            [
                'title' => '🚀 Space Defender: Synonym Interceptor',
                'type' => 'space_defender',
                'course_id' => null,
                'data_json' => [
                    'title' => '🚀 Space Defender: Synonym Interceptor',
                    'speed' => 'normal',
                    'challenges' => [
                        [
                            'question' => 'Shoot the Synonym of "Pinnacle":',
                            'targetWord' => 'Summit',
                            'distractors' => ['Valley', 'Base']
                        ],
                        [
                            'question' => 'Shoot the Synonym of "Fragile":',
                            'targetWord' => 'Delicate',
                            'distractors' => ['Sturdy', 'Durable']
                        ],
                        [
                            'question' => 'Shoot the Synonym of "Meticulous":',
                            'targetWord' => 'Thorough',
                            'distractors' => ['Careless', 'Hasty']
                        ],
                        [
                            'question' => 'Shoot the Synonym of "Bizarre":',
                            'targetWord' => 'Peculiar',
                            'distractors' => ['Normal', 'Typical']
                        ],
                        [
                            'question' => 'Shoot the Synonym of "Valiant":',
                            'targetWord' => 'Heroic',
                            'distractors' => ['Feeble', 'Timid']
                        ]
                    ]
                ]
            ],
            [
                'title' => '🚀 Space Defender: Suffix Galaxy Defense',
                'type' => 'space_defender',
                'course_id' => null,
                'data_json' => [
                    'title' => '🚀 Space Defender: Suffix Galaxy Defense',
                    'speed' => 'normal',
                    'challenges' => [
                        [
                            'question' => 'Suffix turning "Care" into (without care):',
                            'targetWord' => 'Careless',
                            'distractors' => ['Careful', 'Caring']
                        ],
                        [
                            'question' => 'Suffix turning "Help" into (full of help):',
                            'targetWord' => 'Helpful',
                            'distractors' => ['Helpless', 'Helping']
                        ],
                        [
                            'question' => 'Suffix turning "Bright" into a noun:',
                            'targetWord' => 'Brightness',
                            'distractors' => ['Brightly', 'Brighter']
                        ],
                        [
                            'question' => 'Suffix turning "Act" into a person:',
                            'targetWord' => 'Actor',
                            'distractors' => ['Action', 'Active']
                        ],
                        [
                            'question' => 'Suffix turning "Teach" into a profession:',
                            'targetWord' => 'Teacher',
                            'distractors' => ['Teaching', 'Teachable']
                        ]
                    ]
                ]
            ],
            [
                'title' => '🚀 Space Defender: Compound Words Sector',
                'type' => 'space_defender',
                'course_id' => null,
                'data_json' => [
                    'title' => '🚀 Space Defender: Compound Words Sector',
                    'speed' => 'normal',
                    'challenges' => [
                        [
                            'question' => 'Pair with "Sun" to form a garden flower:',
                            'targetWord' => 'Sunflower',
                            'distractors' => ['Sunwater', 'Sunearth']
                        ],
                        [
                            'question' => 'Pair with "Rain" to form an arc of color:',
                            'targetWord' => 'Rainbow',
                            'distractors' => ['Rainfall', 'Raindrop']
                        ],
                        [
                            'question' => 'Pair with "Book" to form study furniture:',
                            'targetWord' => 'Bookshelf',
                            'distractors' => ['Bookmark', 'Bookcase']
                        ],
                        [
                            'question' => 'Pair with "Tooth" to form a dental brush:',
                            'targetWord' => 'Toothbrush',
                            'distractors' => ['Toothpaste', 'Toothpick']
                        ],
                        [
                            'question' => 'Pair with "Butter" to form a winged insect:',
                            'targetWord' => 'Butterfly',
                            'distractors' => ['Buttercup', 'Buttermilk']
                        ]
                    ]
                ]
            ],
            [
                'title' => '🚀 Space Defender: Phrasal Verbs Squadron',
                'type' => 'space_defender',
                'course_id' => null,
                'data_json' => [
                    'title' => '🚀 Space Defender: Phrasal Verbs Squadron',
                    'speed' => 'normal',
                    'challenges' => [
                        [
                            'question' => 'Complete: "Give ___" (surrender / quit):',
                            'targetWord' => 'Up',
                            'distractors' => ['In', 'Down']
                        ],
                        [
                            'question' => 'Complete: "Call ___" (cancel an event):',
                            'targetWord' => 'Off',
                            'distractors' => ['Out', 'Away']
                        ],
                        [
                            'question' => 'Complete: "Make ___" (invent an excuse):',
                            'targetWord' => 'Up',
                            'distractors' => ['Over', 'For']
                        ],
                        [
                            'question' => 'Complete: "Look ___" (take care of a child):',
                            'targetWord' => 'After',
                            'distractors' => ['At', 'For']
                        ],
                        [
                            'question' => 'Complete: "Turn ___" (reject an invitation):',
                            'targetWord' => 'Down',
                            'distractors' => ['Back', 'Off']
                        ]
                    ]
                ]
            ],

            // ==========================================
            // 5. 🎈 BALLOON WORD POP (SKY TAP GAME)
            // ==========================================
            [
                'title' => '🎈 Balloon Pop: Nature & Weather Words',
                'type' => 'balloon_pop',
                'course_id' => null,
                'data_json' => [
                    'title' => '🎈 Balloon Pop: Nature & Weather Words',
                    'question' => 'Pop all Nature and Weather Words!',
                    'correctWords' => ['Thunder', 'Rainbow', 'Breeze', 'Meadow', 'Horizon', 'Cascade', 'Sunrise', 'Blizzard'],
                    'wrongWords' => ['Toaster', 'Keyboard', 'Elevator', 'Smartphone', 'Plastic', 'Traffic', 'Wallet'],
                    'speed' => 'normal'
                ]
            ],
            [
                'title' => '🎈 Balloon Pop: Healthy Foods & Fruits',
                'type' => 'balloon_pop',
                'course_id' => null,
                'data_json' => [
                    'title' => '🎈 Balloon Pop: Healthy Foods & Fruits',
                    'question' => 'Pop all Healthy Foods and Fruits!',
                    'correctWords' => ['Avocado', 'Pomegranate', 'Almonds', 'Broccoli', 'Blueberry', 'Spinach', 'Walnuts'],
                    'wrongWords' => ['Battery', 'Stapler', 'Gasoline', 'Concrete', 'Cardboard', 'Headphones'],
                    'speed' => 'normal'
                ]
            ],
            [
                'title' => '🎈 Balloon Pop: Sight Words for Beginners',
                'type' => 'balloon_pop',
                'course_id' => null,
                'data_json' => [
                    'title' => '🎈 Balloon Pop: Sight Words for Beginners',
                    'question' => 'Pop the High-Frequency Sight Words!',
                    'correctWords' => ['Because', 'Through', 'Always', 'Before', 'Around', 'Another', 'Between', 'Together'],
                    'wrongWords' => ['Xylophone', 'Photosynthesis', 'Pterodactyl', 'Encyclopedic', 'Microbiology'],
                    'speed' => 'gentle'
                ]
            ],
            [
                'title' => '🎈 Balloon Pop: Musical Instruments',
                'type' => 'balloon_pop',
                'course_id' => null,
                'data_json' => [
                    'title' => '🎈 Balloon Pop: Musical Instruments',
                    'question' => 'Pop the Musical Instruments!',
                    'correctWords' => ['Clarinet', 'Trumpet', 'Violin', 'Saxophone', 'Trombone', 'Cello', 'Flute', 'Accordion'],
                    'wrongWords' => ['Microscope', 'Telescope', 'Thermometer', 'Barometer', 'Compass', 'Calculator'],
                    'speed' => 'normal'
                ]
            ],
            [
                'title' => '🎈 Balloon Pop: Ocean Creatures',
                'type' => 'balloon_pop',
                'course_id' => null,
                'data_json' => [
                    'title' => '🎈 Balloon Pop: Ocean Creatures',
                    'question' => 'Pop all Ocean Animals & Sea Creatures!',
                    'correctWords' => ['Dolphin', 'Jellyfish', 'Octopus', 'Seahorse', 'Whale', 'Starfish', 'Lobster', 'Stingray'],
                    'wrongWords' => ['Cheetah', 'Giraffe', 'Eagle', 'Kangaroo', 'Chimpanzee', 'Grizzly'],
                    'speed' => 'breezy'
                ]
            ],
        ];

        foreach ($activities as $act) {
            Activity::create([
                'title' => $act['title'],
                'type' => $act['type'],
                'course_id' => $act['course_id'],
                'data_json' => $act['data_json'],
                'created_by' => null,
            ]);
        }

        $this->command->info('Successfully seeded ' . count($activities) . ' game activities (5 for each game type)!');
    }
}
