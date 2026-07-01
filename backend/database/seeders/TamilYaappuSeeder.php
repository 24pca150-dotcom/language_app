<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Chapter;
use App\Models\Content;
use App\Models\Assessment;
use App\Models\AssessmentQuestion;
use App\Models\QuestionOption;
use App\Models\Level;
use Illuminate\Support\Facades\DB;

class TamilYaappuSeeder extends Seeder
{
    public function run()
    {
        // 1. Find Level 1 (Tamil - 1.0)
        $level = Level::find(1);
        if (!$level) {
            $level = Level::where('name', 'like', '%Tamil%')->first();
        }
        if (!$level) {
            $this->command->error('Tamil Level 1 not found. Please ensure Tamil course and levels exist.');
            return;
        }

        // 2. Clear old data if it exists to make it idempotent
        $oldChapter = Chapter::where('code', 'TAM-CH001')->first();
        if ($oldChapter) {
            DB::table('level_chapter')->where('chapter_id', $oldChapter->id)->delete();
            DB::table('content_chapters')->where('chapter_id', $oldChapter->id)->delete();
            
            // Delete questions and assessments linked to this chapter
            $assessments = Assessment::where('chapter_id', $oldChapter->id)->get();
            foreach ($assessments as $assess) {
                $questions = AssessmentQuestion::where('assessment_id', $assess->id)->get();
                foreach ($questions as $q) {
                    QuestionOption::where('question_id', $q->id)->delete();
                    $q->delete();
                }
                $assess->delete();
            }
            
            // Delete content pages linked to this chapter
            Content::where('name', 'அழகுத் தமிழ் யாப்பு')->delete();
            
            $oldChapter->delete();
        }

        // 3. Create the Chapter
        $chapter = Chapter::create([
            'name' => 'அழகுத் தமிழ் யாப்பு',
            'code' => 'TAM-CH001',
            'description' => json_encode([
                'time' => time(),
                'blocks' => [
                    [
                        'type' => 'paragraph',
                        'data' => ['text' => 'அழகுத் தமிழ் யாப்புப் பாடம்']
                    ]
                ],
                'version' => '2.31.6'
            ]),
            'sort_order' => 1,
            'is_active' => true,
        ]);

        // 3. Associate Chapter with Level
        DB::table('level_chapter')->insert([
            'level_id' => $level->id,
            'chapter_id' => $chapter->id,
            'sort_order' => 1,
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // 4. Prepare Editor.js JSON Content
        $textContentJson = json_encode([
            'time' => time() * 1000,
            'blocks' => [
                [
                    'id' => 'header_1',
                    'type' => 'header',
                    'data' => [
                        'text' => 'அழகுத் தமிழ் யாப்பு',
                        'level' => 2
                    ]
                ],
                [
                    'id' => 'paragraph_1',
                    'type' => 'paragraph',
                    'data' => [
                        'text' => '<b>யாப்பிலக்கணம்</b> அப்படின்னா என்ன தெரியுமா குட்டீஸ்? தமிழ்ல செய்யுள் அல்லது மரபுக்கவிதைகள் எழுதுறதுக்கான விதிகளைச் சொல்றதுதான் யாப்பிலக்கணம். இதை நாம கத்துக்கிட்டோம்னா, ரொம்ப ஈஸியா செய்யுள் எழுதுறதுக்கான அடிப்படை விதிகளைப் புரிஞ்சுக்கலாம்!'
                    ]
                ],
                [
                    'id' => 'header_2',
                    'type' => 'header',
                    'data' => [
                        'text' => 'யாப்பின் உறுப்புகள்',
                        'level' => 3
                    ]
                ],
                [
                    'id' => 'list_1',
                    'type' => 'list',
                    'data' => [
                        'style' => 'ordered',
                        'items' => [
                            ['content' => 'எழுத்து', 'items' => []],
                            ['content' => 'அசை', 'items' => []],
                            ['content' => 'சீர்', 'items' => []],
                            ['content' => 'தளை', 'items' => []],
                            ['content' => 'அடி', 'items' => []],
                            ['content' => 'தொடை', 'items' => []]
                        ]
                    ]
                ],
                [
                    'id' => 'header_3',
                    'type' => 'header',
                    'data' => [
                        'text' => 'எழுத்து',
                        'level' => 3
                    ]
                ],
                [
                    'id' => 'paragraph_2',
                    'type' => 'paragraph',
                    'data' => [
                        'text' => 'யாப்பிலக்கணத்துல அசை அப்படின்னு ஒன்னு இருக்கு. அதுக்கு அடிப்படையான விஷயமே நாம எழுதுற எழுத்துகள்தான்.'
                    ]
                ],
                [
                    'id' => 'paragraph_3',
                    'type' => 'paragraph',
                    'data' => [
                        'text' => '"எழுதப்படுறதுனாலதான் இதுக்கு எழுத்து" அப்படின்னு இலக்கணத்துல சொல்றாங்க. நாம பேசுற ஒலியை (சத்தத்தை) ஒரு வடிவமா காட்ட உதவுறதுதான் இந்த எழுத்து.'
                    ]
                ],
                [
                    'id' => 'paragraph_4',
                    'type' => 'paragraph',
                    'data' => [
                        'text' => 'தமிழ் மொழியில ஒலியோட அளவை <b>மாத்திரை</b> அப்படின்னு சொல்வோம். மாத்திரைன்னா நாம உடம்புக்குப் போடுற மாத்திரை இல்ல குட்டீஸ்! நாம சாதாரணமா ஒருமுறை கண்ணை இமைக்கிற நேரமோ, இல்ல ஒருமுறை கைநொடி (சுடக்கு) போடுற நேரமோதான் ஒரு மாத்திரை. அதாவது, கண்ணிமைக்கும் நேரம் அல்லது கைநொடிக்கும் நேரம்தான் ஒரு மாத்திரை.'
                    ]
                ],
                [
                    'id' => 'header_4',
                    'type' => 'header',
                    'data' => [
                        'text' => 'எழுத்தின் வகைகள்',
                        'level' => 3
                    ]
                ],
                [
                    'id' => 'paragraph_5',
                    'type' => 'paragraph',
                    'data' => [
                        'text' => 'செய்யுளைப் பிரிச்சுப் புரிஞ்சுக்கிறதுக்கு நாம மூணு முக்கியமான எழுத்து வகைகளைத் தெரிஞ்சுக்கணும். அது என்னன்னா: குறில், நெடில், அப்புறம் ஒற்று எழுத்துகள்.'
                    ]
                ],
                [
                    'id' => 'paragraph_6',
                    'type' => 'paragraph',
                    'data' => [
                        'text' => '<b>1. குறில்</b> – ஒரு மாத்திரை அளவுல ஒலிக்கிற எழுத்துகளைத்தான் குறில் எழுத்துகள்னு சொல்றோம். அ, இ, உ, எ, ஒ ஆகிய ஐந்து உயிர் எழுத்துகளும் உயிர்க்குறில் ஆகும். மெய்யெழுத்துகள் பதினெட்டும் இந்த உயிரெழுத்துகளோட சேர்ந்து உயிர்மெய்க்குறில் எழுத்துகளை உருவாக்கும்.'
                    ]
                ],
                [
                    'id' => 'paragraph_7',
                    'type' => 'paragraph',
                    'data' => [
                        'text' => '<b>உயிர்க் குறில்:</b> அ, இ, உ, எ, ஒ'
                    ]
                ],
                [
                    'id' => 'header_5',
                    'type' => 'header',
                    'data' => [
                        'text' => 'உயிர்மெய்க் குறில் அட்டவணை',
                        'level' => 4
                    ]
                ],
                [
                    'id' => 'list_2',
                    'type' => 'list',
                    'data' => [
                        'style' => 'unordered',
                        'items' => [
                            ['content' => '<b>க்</b> - க, கி, கு, கெ, கொ', 'items' => []],
                            ['content' => '<b>ங்</b> - ங, ஙி, ஙு, ஙெ, ஙொ', 'items' => []],
                            ['content' => '<b>ச்</b> - ச, சி, சு, செ, சொ', 'items' => []],
                            ['content' => '<b>ஞ்</b> - ஞ, ஞி, ஞு, ஞெ, ஞொ', 'items' => []],
                            ['content' => '<b>ட்</b> - ட, டி, டு, டெ, டொ', 'items' => []],
                            ['content' => '<b>ண்</b> - ண, ணி, ணு, ணெ, ணொ', 'items' => []],
                            ['content' => '<b>த்</b> - த, தி, து, தெ, தொ', 'items' => []],
                            ['content' => '<b>ந்</b> - ந, நி, நு, நெ, நொ', 'items' => []],
                            ['content' => '<b>ப்</b> - ப, பி, பு, பெ, பொ', 'items' => []],
                            ['content' => '<b>ம்</b> - ம, மி, மு, மெ, மொ', 'items' => []],
                            ['content' => '<b>ய்</b> - ய, யி, யு, யெ, யொ', 'items' => []],
                            ['content' => '<b>ர்</b> - ர, ரி, ரு, ரெ, ரொ', 'items' => []],
                            ['content' => '<b>ல்</b> - ல, லி, லு, லெ, லொ', 'items' => []],
                            ['content' => '<b>வ்</b> - வ, வி, வு, வெ, வொ', 'items' => []],
                            ['content' => '<b>ழ்</b> - ழ, ழி, ழு, ழெ, ழொ', 'items' => []],
                            ['content' => '<b>ள்</b> - ள, ளி, ளு, ளெ, ளொ', 'items' => []],
                            ['content' => '<b>ற்</b> - ற, றி, று, றெ, றொ', 'items' => []],
                            ['content' => '<b>ன்</b> - ன, னி, னு, நெ, நொ', 'items' => []]
                        ]
                    ]
                ],
                [
                    'id' => 'paragraph_8',
                    'type' => 'paragraph',
                    'data' => [
                        'text' => '<b>2. நெடில்</b> – இரண்டு மாத்திரை அளவுல ஒலிக்கிற எழுத்துகளை நெடில் எழுத்துகள்னு சொல்றோம். ஆ, ஈ, ஊ, ஏ, ஐ, ஓ, ஔ ஆகிய ஏழு உயிர் எழுத்துகளும் உயிர்நெடில் ஆகும். மெய்யெழுத்துகள் பதினெட்டும் இந்த உயிரெழுத்துகளோட சேர்ந்து உயிர்மெய்நெடில் எழுத்துகளை உருவாக்கும்.'
                    ]
                ],
                [
                    'id' => 'paragraph_9',
                    'type' => 'paragraph',
                    'data' => [
                        'text' => '<b>உயிர் நெடில்:</b> ஆ, ஈ, ஊ, ஏ, ஐ, ஓ, ஔ'
                    ]
                ],
                [
                    'id' => 'header_6',
                    'type' => 'header',
                    'data' => [
                        'text' => 'உயிர்மெய் நெடில் அட்டவணை',
                        'level' => 4
                    ]
                ],
                [
                    'id' => 'list_3',
                    'type' => 'list',
                    'data' => [
                        'style' => 'unordered',
                        'items' => [
                            ['content' => '<b>க்</b> - கா, கீ, கூ, கே, கோ, கை, கௌ', 'items' => []],
                            ['content' => '<b>ங்</b> - ஙா, ஙீ, ஙூ, ஙே, ஙோ, ஙை, ஙௌ', 'items' => []],
                            ['content' => '<b>ச்</b> - சா, சீ, சூ, சே, சோ, சை, சௌ', 'items' => []],
                            ['content' => '<b>ஞ்</b> - ஞா, ஞீ, ஞூ, ஞே, ஞோ, ஞை, ஞௌ', 'items' => []],
                            ['content' => '<b>ட்</b> - டா, டீ, டூ, டே, டோ, டை, டௌ', 'items' => []],
                            ['content' => '<b>ண்</b> - ணா, ணீ, ணூ, ணே, ணோ, ணை, ணௌ', 'items' => []],
                            ['content' => '<b>த்</b> - தா, தீ, தூ, தே, தோ, தை, தௌ', 'items' => []],
                            ['content' => '<b>ந்</b> - நா, நீ, நூ, நே, நோ, நை, நௌ', 'items' => []],
                            ['content' => '<b>ப்</b> - பா, பீ, பூ, பே, போ, பை, bௌ', 'items' => []],
                            ['content' => '<b>ம்</b> - மா, மீ, மூ, மே, மோ, மை, மௌ', 'items' => []],
                            ['content' => '<b>ய்</b> - யா, யீ, யூ, யே, யோ, யை, யௌ', 'items' => []],
                            ['content' => '<b>ர்</b> - ரா, ரீ, ரூ, ரே, ரோ, ரை, ரௌ', 'items' => []],
                            ['content' => '<b>ல்</b> - லா, லீ, லூ, லே, லோ, லை, லௌ', 'items' => []],
                            ['content' => '<b>வ்</b> - வா, வீ, வூ, வே, வோ, வை, வௌ', 'items' => []],
                            ['content' => '<b>ழ்</b> - ழா, ழீ, ழூ, ழே, ழோ, ழை, ழௌ', 'items' => []],
                            ['content' => '<b>ள்</b> - ளா, ளீ, ளூ, ளே, ளோ, ளை, ளௌ', 'items' => []],
                            ['content' => '<b>ற்</b> - றா, றீ, றூ, றே, றோ, றை, றௌ', 'items' => []],
                            ['content' => '<b>ன்</b> - னா, னீ, னூ, னே, னோ, னை, னௌ', 'items' => []]
                        ]
                    ]
                ],
                [
                    'id' => 'paragraph_10',
                    'type' => 'paragraph',
                    'data' => [
                        'text' => '<b>3. மெய்</b> – க், ங், ச், ஞ், ட், ண், த், ந், ப், ம், ய், ர், ல், வ், ழ், ள், ற், ன் ஆகிய 18 மெய்யெழுத்துகளும் அரை மாத்திரை அளவுல ஒலிக்கும்.'
                    ]
                ],
                [
                    'id' => 'paragraph_11',
                    'type' => 'paragraph',
                    'data' => [
                        'text' => 'இப்படி எழுத்துகளை மூணா பிரிச்சு அதோட வகைகளைத் தெரிஞ்சுக்கிறது, அசை பிரிக்க ரொம்ப ரொம்ப முக்கியம் குட்டீஸ்.'
                    ]
                ],
                [
                    'id' => 'paragraph_12',
                    'type' => 'paragraph',
                    'data' => [
                        'text' => 'குறில், நெடில், ஒற்று இதைத் தவிர சில சிறப்பு எழுத்துகளையும் நாம தெரிஞ்சுக்கணும். ஏன்னா, செய்யuள்ல ஓசை அல்லது தளை தட்டும்போது, புலவர்கள் மாத்திரை அளவைக் கூட்டியோ குறைச்சோ இதைப் பயன்படுத்துவாங்க.'
                    ]
                ],
                [
                    'id' => 'header_7',
                    'type' => 'header',
                    'data' => [
                        'text' => '4. குற்றியலுகரம்',
                        'level' => 3
                    ]
                ],
                [
                    'id' => 'paragraph_13',
                    'type' => 'paragraph',
                    'data' => [
                        'text' => 'உகரம் எழுத்து தனியாவோ அல்லது ஒரு குறில் எழுத்துக்கு அடுத்து வரும்போதோ 1 மாத்திரை பெறும். ஆனா கு, சு, டு, து, பு, று ஆகிய ஆறு எழுத்துகளும் சில இடங்கள்ல அரை மாத்திரையா குறைஞ்சு ஒலிக்கும். இதைத்தான் நாம <b>குற்றியலுகரம்</b> அப்படின்னு சொல்றோம்.'
                    ]
                ],
                [
                    'id' => 'table_1',
                    'type' => 'table',
                    'data' => [
                        'withHeadings' => true,
                        'content' => [
                            ['எண்', 'குற்றியலுகரம் வரும் இடங்கள்', 'சான்று'],
                            ['1', 'நெடில்', 'பாகு, காசு, கூறு'],
                            ['2', 'நெடில் + ஒற்று', 'பாக்கு, கூற்று, வாத்து'],
                            ['3', 'குறிலிணை', 'இறகு, முரசு, மரபு'],
                            ['4', 'குறிலிணை + ஒற்று', 'அரங்கு, மருந்து, சுழற்று'],
                            ['5', 'குறில்நெடில்', 'அசோகு, இயைபு, கெடாது'],
                            ['6', 'குறில்நெடில் + ஒற்று', 'அமைச்சு, நகைப்பு, நிலைத்து'],
                            ['7', 'குறில் + ஒற்று', 'செக்கு, தச்சு, பத்து']
                        ]
                    ]
                ],
                [
                    'id' => 'header_8',
                    'type' => 'header',
                    'data' => [
                        'text' => '5. குற்றியலிகரம்',
                        'level' => 3
                    ]
                ],
                [
                    'id' => 'paragraph_14',
                    'type' => 'paragraph',
                    'data' => [
                        'text' => 'ஒரு குற்றியலுகர சொல் நிலைமொழியில இருக்கிறப்போ, வருமொழியில \'ய\' வரிசை எழுத்து வந்தா, அது இகரமா மாறும். அப்படி மாறும்போது அதோட மாத்திரை அளவு அரை மாத்திரையா குறைஞ்சிடும். இதுதான் <b>குற்றியலிகரம்</b>.'
                    ]
                ],
                [
                    'id' => 'paragraph_15',
                    'type' => 'paragraph',
                    'data' => [
                        'text' => '<b>உதாரணமா:</b> காசு கூட்டல் யாது, காசியாது அப்படின்னு மாறும். இங்க \'சு\' என்ற குற்றியலுகரம், \'யா\' வந்ததுனால \'சி\' அப்படின்னு குற்றியலிகரமா மாறிடுச்சு. இந்த \'சி\' எழுத்துக்கு அரை மாத்திரைதான் அளவு.'
                    ]
                ],
                [
                    'id' => 'header_9',
                    'type' => 'header',
                    'data' => [
                        'text' => '6. ஐகாரக் குறுக்கம்',
                        'level' => 3
                    ]
                ],
                [
                    'id' => 'paragraph_16',
                    'type' => 'paragraph',
                    'data' => [
                        'text' => 'ஐகாரம் தனியா வரும்போதோ அல்லது அளபெடுக்கும்போதோ இரண்டு மாத்திரை பெறும். ஆனா ஒரு சொல்லோட முதலிலோ, இடையிலோ அல்லது கடைசியிலோ வரும்போது அதோட மாத்திரை அளவு குறையும். இததான் <b>ஐகாரக்குறுக்கம்</b> அப்படின்னு சொல்வோம்.'
                    ]
                ],
                [
                    'id' => 'table_2',
                    'type' => 'table',
                    'data' => [
                        'withHeadings' => true,
                        'content' => [
                            ['எண்', 'வருமிடம்', 'மாத்திரை அளவு', 'சான்று'],
                            ['1', 'மொழி முதல்', 'ஒன்றரை', 'ஐப்பசி, வைகாசி'],
                            ['2', 'மொழி இடை', 'ஒன்று', 'இடையன்'],
                            ['3', 'மொழி கடை', 'ஒன்று', 'வாழை']
                        ]
                    ]
                ],
                [
                    'id' => 'header_10',
                    'type' => 'header',
                    'data' => [
                        'text' => '7. அளபெடை',
                        'level' => 3
                    ]
                ],
                [
                    'id' => 'paragraph_17',
                    'type' => 'paragraph',
                    'data' => [
                        'text' => 'அளபெடைங்கிறது உயிரளபெடை, ஒற்றளபெடைன்னு இரண்டு வகைப்படும்.'
                    ]
                ],
                [
                    'id' => 'paragraph_18',
                    'type' => 'paragraph',
                    'data' => [
                        'text' => '<b>உயிரளபெடை:</b> உயிர் எழுத்துகள்ல இருக்கிற ஏழு நெடில் எழுத்துகளும் அளபெடுக்கும். அதாவது 2 மாத்திரை அளவில இருந்து கூடி 3 மாத்திரை அளவா ஒலிக்கும். அப்படி அளபெடுத்ததை நமக்குக் காட்ட, அந்த நெடில் எழுத்தோட இனமான குறில் எழுத்து அதுக்குப் பக்கத்துல வரும்.'
                    ]
                ],
                [
                    'id' => 'paragraph_19',
                    'type' => 'paragraph',
                    'data' => [
                        'text' => 'உயிரளபெடைங்கிறது தனிநிலை, சொல்லோட முதல், இடை, கடை என நான்கு இடங்களில் அளபெடுத்து வரும்.'
                    ]
                ],
                [
                    'id' => 'list_4',
                    'type' => 'list',
                    'data' => [
                        'style' => 'unordered',
                        'items' => [
                            ['content' => '<b>தனிநிலை அளபெடை</b> – ஆஅ, ஈஇ, ஊஉ, ஏஎ, ஐஇ, ஓஒ, ஔஉ', 'items' => []],
                            ['content' => '<b>முதல்நிலை அளபெடை</b> – ஆஅரிடம், ஈஇரிது, ஊஉரிடம்', 'items' => []],
                            ['content' => '<b>இடைநிலை அளபெடை</b> – படாஅகை, தழீஇயது, கெழீஇயது', 'items' => []],
                            ['content' => '<b>கடைநிலை அளபெடை</b> – கடாஅ, குரீஇ, கடைஇ', 'items' => []]
                        ]
                    ]
                ],
                [
                    'id' => 'paragraph_20',
                    'type' => 'paragraph',
                    'data' => [
                        'text' => '<b>ஒற்றளபெடை:</b> ங், ஞ், ண், ந், ம், ன், வ், ய், ல், ள் ஆகிய பத்து மெய் எழுத்துகளும் குறில் எழுத்துக்குப் பக்கத்துலயோ, இல்ல குறிலிணைக்குப் பக்கத்துலயோ அளபெடுக்கும். இங்க மெய் எழுத்துகள் தமக்குரிய அரை மாத்திரை அளவில இருந்து கூடி 1 மாத்திரையாக ஒலிக்கும்.'
                    ]
                ],
                [
                    'id' => 'list_5',
                    'type' => 'list',
                    'data' => [
                        'style' => 'unordered',
                        'items' => [
                            ['content' => '<b>ங்</b> – மங்ங்கலம், அரங்ங்கம்', 'items' => []],
                            ['content' => '<b>ஞ்</b> – மஞ்ஞ்சு, முரஞ்ஞ்சு', 'items' => []]
                        ]
                    ]
                ],
                [
                    'id' => 'paragraph_21',
                    'type' => 'paragraph',
                    'data' => [
                        'text' => 'இப்படிச் சொல்லப்பட்ட எழுத்துகள் எல்லாமே, கவிஞர்கள் கவிதை எழுதும்போது தேவையான ஓசையையும் சீரையும் அமைக்க ரொம்பவே உதவியா இருக்கும்!'
                    ]
                ]
            ],
            'version' => '2.31.6'
        ]);

        // 5. Create Content Page
        $content = Content::create([
            'name' => 'அழகுத் தமிழ் யாப்பு',
            'title' => 'அழகுத் தமிழ் யாப்பு',
            'text_content' => $textContentJson,
            'sort_order' => 1,
            'is_active' => true,
        ]);

        // 6. Link Content to Chapter
        DB::table('content_chapters')->insert([
            'content_id' => $content->id,
            'chapter_id' => $chapter->id,
            'sort_order' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // 7. Create Assessment
        $assessment = Assessment::create([
            'level_id' => $level->id,
            'chapter_id' => $chapter->id,
            'title' => 'அழகுத் தமிழ் யாப்பு - மதிப்பீடு',
            'description' => 'அழகுத் தமிழ் யாப்புப் பாடப் பகுதிக்கான மதிப்பீடு',
            'pass_percentage' => 70.00,
            'total_marks' => 100,
            'passing_marks' => 70,
            'duration_minutes' => 10,
            'is_mandatory' => true,
            'is_active' => true,
            'allow_restart' => true,
            'activity_type' => 'plain',
            'review_mode' => 'after_completion',
        ]);

        // 8. Questions and Options
        $questionsData = [
            [
                'text' => 'யாப்பிலக்கணம் எதனை விளக்குகிறது?',
                'options' => [
                    ['text' => 'உரைநடை எழுதுவதற்கான விதிகள்', 'correct' => false],
                    ['text' => 'செய்யுள் (மரபுக்கவிதை) எழுதுவதற்கான இலக்கணம்', 'correct' => true],
                    ['text' => 'பேச்சு வழக்கு சொற்கள்', 'correct' => false],
                    ['text' => 'எழுத்துக்கூட்டி வாசித்தல்', 'correct' => false],
                ]
            ],
            [
                'text' => 'யாப்பின் உறுப்புகள் எத்தனை வகைப்படும்?',
                'options' => [
                    ['text' => '5', 'correct' => false],
                    ['text' => '6', 'correct' => true],
                    ['text' => '7', 'correct' => false],
                    ['text' => '8', 'correct' => false],
                ]
            ],
            [
                'text' => 'குறில் எழுத்துக்களின் மாத்திரை அளவு என்ன?',
                'options' => [
                    ['text' => 'அரை மாத்திரை (1/2)', 'correct' => false],
                    ['text' => 'ஒரு மாத்திரை (1)', 'correct' => true],
                    ['text' => 'இரண்டு மாத்திரை (2)', 'correct' => false],
                    ['text' => 'மூன்று மாத்திரை (3)', 'correct' => false],
                ]
            ],
            [
                'text' => 'மெய் எழுத்துக்களின் மாத்திரை அளவு என்ன?',
                'options' => [
                    ['text' => 'அரை மாத்திரை (1/2)', 'correct' => true],
                    ['text' => 'ஒரு மாத்திரை (1)', 'correct' => false],
                    ['text' => 'இரண்டு மாத்திரை (2)', 'correct' => false],
                    ['text' => 'மூன்று மாத்திரை (3)', 'correct' => false],
                ]
            ],
            [
                'text' => '\'பாகு, காசு, கூறு\' - இவை எவ்வகை குற்றியலுகரத்திற்குச் சான்றுகளாகும்?',
                'options' => [
                    ['text' => 'நெடிற்றொடர்க் குற்றியலுகரம் (நெடில்)', 'correct' => true],
                    ['text' => 'ஆய்தத்தொடர்க் குற்றியலுகரம்', 'correct' => false],
                    ['text' => 'வன்தொடர்க் குற்றியலுகரம்', 'correct' => false],
                    ['text' => 'மென்தொடர்க் குற்றியலுகரம்', 'correct' => false],
                ]
            ]
        ];

        foreach ($questionsData as $qIdx => $qData) {
            $questionTextJson = json_encode([
                'time' => time() * 1000,
                'blocks' => [
                    [
                        'type' => 'paragraph',
                        'data' => [
                            'text' => $qData['text']
                        ]
                    ]
                ],
                'version' => '2.31.6'
            ]);

            $question = AssessmentQuestion::create([
                'assessment_id' => $assessment->id,
                'question_text' => $questionTextJson,
                'question_type' => 'multiple_choice',
                'sort_order' => $qIdx,
            ]);

            foreach ($qData['options'] as $oIdx => $oData) {
                QuestionOption::create([
                    'question_id' => $question->id,
                    'option_text' => $oData['text'],
                    'is_correct' => $oData['correct'],
                    'sort_order' => $oIdx,
                ]);
            }
        }
    }
}
