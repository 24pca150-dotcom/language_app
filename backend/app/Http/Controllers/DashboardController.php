<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Chapter;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    /**
     * Fetch student dashboard analytics and gamified badges.
     */
    public function getStudentStats(Request $request)
    {
        $user = $request->user();
        $userId = $user->id;

        // 1. Overall Completion Progress
        $allowedCourseIds = [];
        if ($user->role === 'student' && $user->tenant_id) {
            $today = now()->toDateString();
            $allowedCourseIds = DB::table('property_packages')
                ->join('properties', 'property_packages.property_id', '=', 'properties.id')
                ->where('properties.tenant_id', $user->tenant_id)
                ->where('property_packages.is_active', true)
                ->whereNotNull('property_packages.course_id')
                ->where(function ($q) use ($today) {
                    $q->whereNull('property_packages.start_date')
                      ->orWhere('property_packages.start_date', '<=', $today);
                })
                ->where(function ($q) use ($today) {
                    $q->whereNull('property_packages.end_date')
                      ->orWhere('property_packages.end_date', '>=', $today);
                })
                ->distinct('property_packages.course_id')
                ->pluck('property_packages.course_id')
                ->toArray();
        }

        $totalChaptersQuery = DB::table('chapters');
        if (!empty($allowedCourseIds)) {
            $totalChaptersQuery->whereIn('chapters.id', function ($query) use ($allowedCourseIds) {
                $query->select('level_chapter.chapter_id')
                    ->from('level_chapter')
                    ->join('levels', 'level_chapter.level_id', '=', 'levels.id')
                    ->join('course_package_levels', 'levels.id', '=', 'course_package_levels.level_id')
                    ->whereIn('course_package_levels.course_id', $allowedCourseIds);
            });
        }
        $totalChapters = $totalChaptersQuery->count();
        
        $completedChaptersQuery = DB::table('user_course_progress')
            ->where('user_id', $userId)
            ->where('status', 'completed')
            ->whereNotNull('chapter_id');
        if (\Schema::hasColumn('user_course_progress', 'content_id')) {
            $completedChaptersQuery->whereNull('content_id');
        }
        $completedChapters = $completedChaptersQuery->distinct('chapter_id')->count('chapter_id');

        $completionPercentage = $totalChapters > 0 
            ? round(($completedChapters / $totalChapters) * 100, 1) 
            : 0;

        // 2. Assessment stats
        $totalAttempts = DB::table('user_assessment_attempts')
            ->where('user_id', $userId)
            ->count();

        $passedAttempts = DB::table('user_assessment_attempts')
            ->where('user_id', $userId)
            ->where('passed', true)
            ->count();

        $averageScore = DB::table('user_assessment_attempts')
            ->where('user_id', $userId)
            ->avg('score');

        $averageScore = $averageScore ? round($averageScore, 1) : 0;

        // 3. Calculate streak dynamically
        $streak = $this->calculateStreak($userId);

        // 4. Calculate XP Points and Gems dynamically (with default baselines)
        $activityCompletions = DB::table('user_course_progress')
            ->where('user_id', $userId)
            ->where('status', 'activity_completed')
            ->count();
        
        $xpPoints = 1250 + ($completedChapters * 100) + ($passedAttempts * 200) + ($totalAttempts * 50) + ($streak * 25) + ($activityCompletions * 75);
        $gems = 85 + ($completedChapters * 15) + ($passedAttempts * 30) + ($streak * 5) + ($activityCompletions * 10);

        // Save to users table so columns are synchronized
        if (\Schema::hasColumn('users', 'xp')) {
            $user->xp = $xpPoints;
        }
        if (\Schema::hasColumn('users', 'gems')) {
            $user->gems = $gems;
        }
        if ($user->isDirty()) {
            $user->save();
        }

        // 5. Course-by-course progressions
        $courseProgressions = [];
        $coursesQuery = \App\Models\Course::where('is_active', true);
        if ($user->role === 'student' && $user->tenant_id) {
            $today = now()->toDateString();
            $coursesQuery->whereIn('id', function ($query) use ($user, $today) {
                $query->select('property_packages.course_id')
                    ->from('property_packages')
                    ->join('properties', 'property_packages.property_id', '=', 'properties.id')
                    ->where('properties.tenant_id', $user->tenant_id)
                    ->where('property_packages.is_active', true)
                    ->whereNotNull('property_packages.course_id')
                    ->where(function ($q) use ($today) {
                        $q->whereNull('property_packages.start_date')
                          ->orWhere('property_packages.start_date', '<=', $today);
                    })
                    ->where(function ($q) use ($today) {
                        $q->whereNull('property_packages.end_date')
                          ->orWhere('property_packages.end_date', '>=', $today);
                    });
            });
        }
        $courses = $coursesQuery->get();
        foreach ($courses as $course) {
            $totalCourseChapters = DB::table('chapters')
                ->join('level_chapter', 'chapters.id', '=', 'level_chapter.chapter_id')
                ->join('levels', 'level_chapter.level_id', '=', 'levels.id')
                ->join('course_package_levels', 'levels.id', '=', 'course_package_levels.level_id')
                ->where('course_package_levels.course_id', $course->id)
                ->count('chapters.id');
                
            $completedCourseChapters = DB::table('user_course_progress')
                ->where('user_id', $userId)
                ->where('status', 'completed')
                ->whereIn('chapter_id', function ($query) use ($course) {
                    $query->select('chapters.id')
                        ->from('chapters')
                        ->join('level_chapter', 'chapters.id', '=', 'level_chapter.chapter_id')
                        ->join('levels', 'level_chapter.level_id', '=', 'levels.id')
                        ->join('course_package_levels', 'levels.id', '=', 'course_package_levels.level_id')
                        ->where('course_package_levels.course_id', $course->id);
                })
                ->distinct('chapter_id')
                ->count('chapter_id');
                
            $percentage = $totalCourseChapters > 0 ? round(($completedCourseChapters / $totalCourseChapters) * 100, 1) : 0;
            
            $courseProgressions[] = [
                'course_id' => $course->id,
                'course_name' => $course->name,
                'total_chapters' => $totalCourseChapters,
                'completed_chapters' => $completedCourseChapters,
                'percentage' => $percentage,
            ];
        }

        // 6. Dynamic Skill Mastery
        $skillMastery = [
            ['name' => 'Literature', 'score' => 0],
            ['name' => 'Ethics', 'score' => 0],
            ['name' => 'Grammar', 'score' => 0],
            ['name' => 'History', 'score' => 0],
            ['name' => 'Vocabulary', 'score' => 0],
            ['name' => 'Translation', 'score' => 0],
        ];
        
        foreach ($courseProgressions as $prog) {
            if (str_contains($prog['course_name'], 'Tamil') || str_contains($prog['course_name'], 'Purananuru')) {
                $skillMastery[0]['score'] = max($skillMastery[0]['score'], $prog['percentage']);
                $skillMastery[2]['score'] = max($skillMastery[2]['score'], round($prog['percentage'] * 0.85));
                $skillMastery[3]['score'] = max($skillMastery[3]['score'], round($prog['percentage'] * 0.75));
            }
            if (str_contains($prog['course_name'], 'Kural') || str_contains($prog['course_name'], 'Thirukkural')) {
                $skillMastery[1]['score'] = max($skillMastery[1]['score'], $prog['percentage']);
                $skillMastery[4]['score'] = max($skillMastery[4]['score'], round($prog['percentage'] * 0.9));
                $skillMastery[5]['score'] = max($skillMastery[5]['score'], round($prog['percentage'] * 0.8));
            }
        }
        
        foreach ($skillMastery as &$skill) {
            if ($skill['score'] == 0) {
                $skill['score'] = rand(15, 35); // simulated baseline
            }
        }

        // 7. Dynamic Weekly Activity
        $weeklyActivity = [0, 0, 0, 0, 0, 0, 0]; // Mon-Sun
        $startOfWeek = date('Y-m-d H:i:s', strtotime('monday this week'));
        
        $progressThisWeek = DB::table('user_course_progress')
            ->where('user_id', $userId)
            ->where('status', 'completed')
            ->where('completed_at', '>=', $startOfWeek)
            ->get(['completed_at']);
            
        foreach ($progressThisWeek as $p) {
            $dayOfWeek = date('N', strtotime($p->completed_at)) - 1;
            if ($dayOfWeek >= 0 && $dayOfWeek <= 6) {
                $weeklyActivity[$dayOfWeek] += 1;
            }
        }
        
        $attemptsThisWeek = DB::table('user_assessment_attempts')
            ->where('user_id', $userId)
            ->where('attempted_at', '>=', $startOfWeek)
            ->get(['attempted_at']);
            
        foreach ($attemptsThisWeek as $a) {
            $dayOfWeek = date('N', strtotime($a->attempted_at)) - 1;
            if ($dayOfWeek >= 0 && $dayOfWeek <= 6) {
                $weeklyActivity[$dayOfWeek] += 1;
            }
        }

        // 8. Dynamic Monthly Study Hours
        $monthlyStudyHours = [];
        for ($i = 5; $i >= 0; $i--) {
            $monthStart = date('Y-m-01 00:00:00', strtotime("-$i months"));
            $monthEnd = date('Y-m-t 23:59:59', strtotime("-$i months"));
            $monthLabel = date('M', strtotime("-$i months"));
            
            $completionsCount = DB::table('user_course_progress')
                ->where('user_id', $userId)
                ->where('status', 'completed')
                ->whereBetween('completed_at', [$monthStart, $monthEnd])
                ->count();
                
            $attemptsCount = DB::table('user_assessment_attempts')
                ->where('user_id', $userId)
                ->whereBetween('attempted_at', [$monthStart, $monthEnd])
                ->count();
                
            $hours = ($completionsCount * 0.5) + ($attemptsCount * 0.3);
            if ($hours == 0) {
                $hours = rand(2, 6);
            }
            
            $monthlyStudyHours[] = [
                'label' => $monthLabel,
                'hours' => round($hours, 1)
            ];
        }

        // 9. Verified Certificates
        $certificates = [];
        foreach ($courseProgressions as $prog) {
            if ($prog['percentage'] >= 100) {
                $certificates[] = [
                    'certificate_id' => 'AW-' . date('Y') . '-' . strtoupper(substr(md5($prog['course_name']), 0, 4)) . '-' . str_pad($userId, 3, '0', STR_PAD_LEFT),
                    'course_name' => $prog['course_name'],
                    'completed_date' => date('M d, Y'),
                    'duration' => ($prog['total_chapters'] * 2) . ' hours',
                ];
            }
        }

        // 10. Dynamic Badges Check
        $badges = [
            [
                'id' => 'first_step',
                'title' => 'First Step',
                'description' => 'Completed your first lesson topic',
                'icon' => '🚀',
                'xp' => 100,
                'unlocked' => $completedChapters >= 1,
            ],
            [
                'id' => 'bookworm',
                'title' => 'Bookworm',
                'description' => 'Read and finished 5+ lesson topics',
                'icon' => '📚',
                'xp' => 150,
                'unlocked' => $completedChapters >= 5,
            ],
            [
                'id' => 'scholar',
                'title' => 'Scholar',
                'description' => 'Scored a perfect 100% on any chapter test',
                'icon' => '🎓',
                'xp' => 300,
                'unlocked' => DB::table('user_assessment_attempts')
                    ->where('user_id', $userId)
                    ->where('score', 100)
                    ->exists(),
            ],
            [
                'id' => 'chapter_champ',
                'title' => 'Chapter Champion',
                'description' => 'Passed 3 or more assessments',
                'icon' => '🏆',
                'xp' => 200,
                'unlocked' => $passedAttempts >= 3,
            ],
            [
                'id' => 'graduation',
                'title' => 'Ultimate Graduation',
                'description' => 'Achieved 100% syllabus completion',
                'icon' => '👑',
                'xp' => 500,
                'unlocked' => $completionPercentage >= 100 && $totalChapters > 0,
            ],
        ];

        $completedChapterQuery = DB::table('user_course_progress')
            ->where('user_id', $userId)
            ->where('status', 'completed')
            ->whereNotNull('chapter_id');
        if (\Schema::hasColumn('user_course_progress', 'content_id')) {
            $completedChapterQuery->whereNull('content_id');
        }
        $completedChapterIds = $completedChapterQuery->pluck('chapter_id')->toArray();

        return response()->json([
            'completion_percentage' => $completionPercentage,
            'completed_chapters' => $completedChapters,
            'total_chapters' => $totalChapters,
            'total_attempts' => $totalAttempts,
            'passed_attempts' => $passedAttempts,
            'average_score' => $averageScore,
            'xp_points' => $xpPoints,
            'gems' => $gems,
            'streak_days' => $streak,
            'course_progressions' => $courseProgressions,
            'skill_mastery' => $skillMastery,
            'weekly_activity' => $weeklyActivity,
            'monthly_study_hours' => $monthlyStudyHours,
            'certificates' => $certificates,
            'badges' => $badges,
            'completed_chapter_ids' => $completedChapterIds,
        ]);
    }

    /**
     * Calculate consecutive days of activity for study streak
     */
    private function calculateStreak($userId)
    {
        $progressDates = DB::table('user_course_progress')
            ->where('user_id', $userId)
            ->whereNotNull('completed_at')
            ->pluck('completed_at')
            ->map(function ($date) {
                return date('Y-m-d', strtotime($date));
            })
            ->toArray();

        $attemptDates = DB::table('user_assessment_attempts')
            ->where('user_id', $userId)
            ->pluck('attempted_at')
            ->map(function ($date) {
                return date('Y-m-d', strtotime($date));
            })
            ->toArray();

        $allDates = array_unique(array_merge($progressDates, $attemptDates));
        rsort($allDates);

        if (empty($allDates)) {
            return 0;
        }

        $streak = 0;
        $today = date('Y-m-d');
        $yesterday = date('Y-m-d', strtotime('-1 day'));

        $mostRecent = $allDates[0];
        if ($mostRecent !== $today && $mostRecent !== $yesterday) {
            return 0;
        }

        $currentDate = $mostRecent;
        foreach ($allDates as $date) {
            if ($date === $currentDate) {
                $streak++;
                $currentDate = date('Y-m-d', strtotime($currentDate . ' -1 day'));
            } else {
                break;
            }
        }

        return $streak;
    }


    /**
     * Fetch student progress analytics for Staff/Admin tracking.
     */
    public function getStudentStatsForStaff(Request $request, $userId)
    {
        $currentUser = $request->user();
        $targetUser = \App\Models\User::findOrFail($userId);
        
        // Security check: Must be staff, and if not super_admin, must match tenant_id
        if ($currentUser->role !== 'super_admin') {
            if ($targetUser->tenant_id !== $currentUser->tenant_id) {
                return response()->json(['error' => 'Unauthorized or User not found.'], 403);
            }
        }

        // Overall Completion Progress (Scoped to the student's assigned tenant courses)
        $allowedCourseIds = [];
        if ($targetUser->role === 'student' && $targetUser->tenant_id) {
            $today = now()->toDateString();
            $allowedCourseIds = DB::table('property_packages')
                ->join('properties', 'property_packages.property_id', '=', 'properties.id')
                ->where('properties.tenant_id', $targetUser->tenant_id)
                ->where('property_packages.is_active', true)
                ->whereNotNull('property_packages.course_id')
                ->where(function ($q) use ($today) {
                    $q->whereNull('property_packages.start_date')
                      ->orWhere('property_packages.start_date', '<=', $today);
                })
                ->where(function ($q) use ($today) {
                    $q->whereNull('property_packages.end_date')
                      ->orWhere('property_packages.end_date', '>=', $today);
                })
                ->distinct('property_packages.course_id')
                ->pluck('property_packages.course_id')
                ->toArray();
        }

        // Course breakdown & Fractional Chapter Completion Progress
        $coursesQuery = \App\Models\Course::where('is_active', true);
        
        if ($targetUser->role === 'student' && $targetUser->tenant_id) {
            $today = now()->toDateString();
            $coursesQuery->whereIn('id', function ($query) use ($targetUser, $today) {
                $query->select('property_packages.course_id')
                    ->from('property_packages')
                    ->join('properties', 'property_packages.property_id', '=', 'properties.id')
                    ->where('properties.tenant_id', $targetUser->tenant_id)
                    ->where('property_packages.is_active', true)
                    ->whereNotNull('property_packages.course_id')
                    ->where(function ($q) use ($today) {
                        $q->whereNull('property_packages.start_date')
                          ->orWhere('property_packages.start_date', '<=', $today);
                    })
                    ->where(function ($q) use ($today) {
                        $q->whereNull('property_packages.end_date')
                          ->orWhere('property_packages.end_date', '>=', $today);
                    });
            });
        }
        
        $courses = $coursesQuery->get();
        $totalChaptersOverall = 0;
        $completedChaptersFractionalOverall = 0;
        $coursesProgress = [];
        
        foreach ($courses as $course) {
            $chapterMappings = DB::table('level_chapter')
                ->join('levels', 'level_chapter.level_id', '=', 'levels.id')
                ->join('course_package_levels', 'levels.id', '=', 'course_package_levels.level_id')
                ->where('course_package_levels.course_id', $course->id)
                ->where('level_chapter.is_active', true)
                ->select('level_chapter.chapter_id', 'level_chapter.level_id')
                ->get();

            $totalCourseChapters = count($chapterMappings);
            $completedCourseChaptersFractional = 0;

            foreach ($chapterMappings as $mapping) {
                $chapId = $mapping->chapter_id;
                $chapterDone = DB::table('user_course_progress')
                    ->where('user_id', $userId)
                    ->where('chapter_id', $chapId)
                    ->whereNull('content_id')
                    ->where('status', 'completed')
                    ->exists();

                if ($chapterDone) {
                    $completedCourseChaptersFractional += 1.0;
                } else {
                    $totalContents = DB::table('content_chapters')
                        ->where('chapter_id', $chapId)
                        ->count();

                    if ($totalContents > 0) {
                        $completedContents = DB::table('user_course_progress')
                            ->where('user_id', $userId)
                            ->where('chapter_id', $chapId)
                            ->whereNotNull('content_id')
                            ->where('status', 'completed')
                            ->distinct('content_id')
                            ->count('content_id');

                        $fraction = min(1.0, $completedContents / $totalContents);
                        $completedCourseChaptersFractional += $fraction;
                    }
                }
            }

            $totalChaptersOverall += $totalCourseChapters;
            $completedChaptersFractionalOverall += $completedCourseChaptersFractional;

            if ($totalCourseChapters > 0 || $completedCourseChaptersFractional > 0) {
                $displayCompleted = ($completedCourseChaptersFractional == floor($completedCourseChaptersFractional))
                    ? (int) $completedCourseChaptersFractional
                    : round($completedCourseChaptersFractional, 1);

                $coursesProgress[] = [
                    'course_name' => $course->name,
                    'total_chapters' => $totalCourseChapters,
                    'completed_chapters' => $displayCompleted,
                    'percentage' => $totalCourseChapters > 0 ? round(($completedCourseChaptersFractional / $totalCourseChapters) * 100, 1) : 0,
                ];
            }
        }

        $completionPercentage = $totalChaptersOverall > 0
            ? round(($completedChaptersFractionalOverall / $totalChaptersOverall) * 100, 1)
            : 0;

        $displayCompletedOverall = ($completedChaptersFractionalOverall == floor($completedChaptersFractionalOverall))
            ? (int) $completedChaptersFractionalOverall
            : round($completedChaptersFractionalOverall, 1);

        // Assessment stats
        $passedAttempts = DB::table('user_assessment_attempts')
            ->where('user_id', $userId)
            ->where('passed', true)
            ->count();

        $averageScore = DB::table('user_assessment_attempts')
            ->where('user_id', $userId)
            ->avg('score');
        $averageScore = $averageScore ? round($averageScore, 1) : 0;

        return response()->json([
            'completion_percentage' => $completionPercentage,
            'completed_chapters' => $displayCompletedOverall,
            'total_chapters' => $totalChaptersOverall,
            'passed_attempts' => $passedAttempts,
            'average_score' => $averageScore,
            'total_courses' => count($coursesProgress),
            'courses_progress' => $coursesProgress,
        ]);
    }

    /**
     * Fetch global school/tenant statistics for Admins & Staff with rich role analytics
     */
    public function getTenantStats(Request $request)
    {
        $currentUser = $request->user();
        $isSuperAdmin = ($currentUser->role === 'super_admin');
        
        // If super admin passes a specific tenant_id query param, filter by that tenant
        $requestedTenantId = $request->query('tenant_id');
        $tenantId = $currentUser->tenant_id;
        $isFilteringSpecificTenant = false;

        if ($isSuperAdmin) {
            if ($requestedTenantId && $requestedTenantId !== 'all') {
                $tenantId = (int) $requestedTenantId;
                $isFilteringSpecificTenant = true;
            }
        } else {
            $isFilteringSpecificTenant = true;
        }

        // Base user query based on role / filter
        $usersQuery = User::query();
        if ($isFilteringSpecificTenant && $tenantId) {
            $usersQuery->where('tenant_id', $tenantId);
        }

        $totalStudents = (clone $usersQuery)->where('role', 'student')->count();
        $totalStaff = (clone $usersQuery)->where('role', 'staff')->count();

        // Active today count
        $todayStart = now()->startOfDay();
        $activeTodayCount = DB::table('user_course_progress')
            ->whereIn('user_id', (clone $usersQuery)->where('role', 'student')->pluck('id'))
            ->where('created_at', '>=', $todayStart)
            ->distinct('user_id')
            ->count('user_id');

        // Count active courses
        if ($isSuperAdmin && !$isFilteringSpecificTenant) {
            $activeCourses = \App\Models\Course::where('is_active', true)->count();
        } else {
            $today = now()->toDateString();
            $activeCourses = DB::table('property_packages')
                ->join('properties', 'property_packages.property_id', '=', 'properties.id')
                ->where('properties.tenant_id', $tenantId)
                ->where('property_packages.is_active', true)
                ->whereNotNull('property_packages.course_id')
                ->where(function ($q) use ($today) {
                    $q->whereNull('property_packages.start_date')
                      ->orWhere('property_packages.start_date', '<=', $today);
                })
                ->where(function ($q) use ($today) {
                    $q->whereNull('property_packages.end_date')
                      ->orWhere('property_packages.end_date', '>=', $today);
                })
                ->distinct('property_packages.course_id')
                ->count('property_packages.course_id');
        }

        // Student IDs
        $studentIds = (clone $usersQuery)->where('role', 'student')->pluck('id')->toArray();
        
        // Total Chapters calculation
        if ($isSuperAdmin && !$isFilteringSpecificTenant) {
            $totalChapters = DB::table('chapters')->count();
        } else {
            $today = now()->toDateString();
            $allowedCourseIds = DB::table('property_packages')
                ->join('properties', 'property_packages.property_id', '=', 'properties.id')
                ->where('properties.tenant_id', $tenantId)
                ->where('property_packages.is_active', true)
                ->whereNotNull('property_packages.course_id')
                ->where(function ($q) use ($today) {
                    $q->whereNull('property_packages.start_date')
                      ->orWhere('property_packages.start_date', '<=', $today);
                })
                ->where(function ($q) use ($today) {
                    $q->whereNull('property_packages.end_date')
                      ->orWhere('property_packages.end_date', '>=', $today);
                })
                ->distinct('property_packages.course_id')
                ->pluck('property_packages.course_id')
                ->toArray();

            $totalChapters = DB::table('chapters')
                ->join('level_chapter', 'chapters.id', '=', 'level_chapter.chapter_id')
                ->join('levels', 'level_chapter.level_id', '=', 'levels.id')
                ->join('course_package_levels', 'levels.id', '=', 'course_package_levels.level_id')
                ->whereIn('course_package_levels.course_id', $allowedCourseIds)
                ->distinct('chapters.id')
                ->count('chapters.id');
        }
        
        $overallCompletionPercentage = 0;
        if (count($studentIds) > 0 && $totalChapters > 0) {
            $completedChaptersQuery = DB::table('user_course_progress')
                ->whereIn('user_id', $studentIds)
                ->where('status', 'completed')
                ->whereNotNull('chapter_id');
            if (\Schema::hasColumn('user_course_progress', 'content_id')) {
                $completedChaptersQuery->whereNull('content_id');
            }
            $completedChapters = $completedChaptersQuery->count();
                
            $maxPossibleCompletions = count($studentIds) * $totalChapters;
            $overallCompletionPercentage = round(($completedChapters / $maxPossibleCompletions) * 100, 1);
        }

        // Top Performers (Students with highest XP)
        $topPerformers = (clone $usersQuery)
            ->where('role', 'student')
            ->orderByDesc('xp')
            ->limit(5)
            ->get(['id', 'name', 'username', 'xp', 'gems'])
            ->map(function ($student) {
                return [
                    'id' => $student->id,
                    'name' => $student->name ?: $student->username,
                    'username' => $student->username,
                    'xp' => $student->xp ?? 0,
                    'gems' => $student->gems ?? 0,
                ];
            });

        // Recent Activities (Last 6 activities across tenant)
        $recentActivities = [];
        if (!empty($studentIds)) {
            $progressItems = DB::table('user_course_progress')
                ->join('users', 'user_course_progress.user_id', '=', 'users.id')
                ->leftJoin('chapters', 'user_course_progress.chapter_id', '=', 'chapters.id')
                ->whereIn('user_course_progress.user_id', $studentIds)
                ->orderByDesc('user_course_progress.created_at')
                ->limit(6)
                ->select(
                    'users.name as user_name',
                    'users.username',
                    'chapters.name as chapter_title',
                    'user_course_progress.status',
                    'user_course_progress.created_at'
                )
                ->get();

            foreach ($progressItems as $item) {
                $timeAgo = \Carbon\Carbon::parse($item->created_at)->diffForHumans();
                $recentActivities[] = [
                    'user_name' => $item->user_name ?: $item->username,
                    'action' => ($item->status === 'completed') ? 'Completed lesson' : 'Practiced activity',
                    'title' => $item->chapter_title ?: 'Lesson topic',
                    'time_ago' => $timeAgo,
                    'type' => 'progress',
                ];
            }
        }

        // Upcoming Live Classes
        $liveClassesQuery = \App\Models\LiveClass::query();
        if ($isFilteringSpecificTenant && $tenantId) {
            $liveClassesQuery->where('tenant_id', $tenantId);
        }
        $upcomingLiveClasses = $liveClassesQuery
            ->where('start_time', '>=', now()->subMinutes(60))
            ->orderBy('start_time', 'asc')
            ->limit(3)
            ->get(['id', 'title', 'instructor_name', 'start_time', 'meeting_link', 'duration_minutes', 'status']);

        // Recent Announcements
        $announcementsQuery = \App\Models\Announcement::query();
        if ($isFilteringSpecificTenant && $tenantId) {
            $announcementsQuery->where(function($q) use ($tenantId) {
                $q->where('tenant_id', $tenantId)->orWhereNull('tenant_id');
            });
        }
        $recentAnnouncements = $announcementsQuery
            ->orderByDesc('created_at')
            ->limit(3)
            ->get(['id', 'title', 'message', 'created_at']);

        // Weekly Activity Trend (Daily completions for last 7 days)
        $weeklyActivity = [
            ['day' => 'Mon', 'count' => 0],
            ['day' => 'Tue', 'count' => 0],
            ['day' => 'Wed', 'count' => 0],
            ['day' => 'Thu', 'count' => 0],
            ['day' => 'Fri', 'count' => 0],
            ['day' => 'Sat', 'count' => 0],
            ['day' => 'Sun', 'count' => 0],
        ];
        $daysOfWeek = ['Mon' => 0, 'Tue' => 1, 'Wed' => 2, 'Thu' => 3, 'Fri' => 4, 'Sat' => 5, 'Sun' => 6];

        if (!empty($studentIds)) {
            $startOfWeek = now()->startOfWeek();
            $completionsThisWeek = DB::table('user_course_progress')
                ->whereIn('user_id', $studentIds)
                ->where('created_at', '>=', $startOfWeek)
                ->get(['created_at']);

            foreach ($completionsThisWeek as $comp) {
                $dayName = \Carbon\Carbon::parse($comp->created_at)->format('D');
                if (isset($daysOfWeek[$dayName])) {
                    $weeklyActivity[$daysOfWeek[$dayName]]['count']++;
                }
            }
        }

        // 4-Skills Mastery Distribution
        $skillBreakdown = [
            ['skill' => 'Listening', 'percentage' => min(95, max(45, (int)($overallCompletionPercentage * 0.9 + 40))), 'color' => '#3b82f6'],
            ['skill' => 'Speaking', 'percentage' => min(95, max(35, (int)($overallCompletionPercentage * 0.8 + 35))), 'color' => '#10b981'],
            ['skill' => 'Reading', 'percentage' => min(98, max(50, (int)($overallCompletionPercentage * 1.1 + 45))), 'color' => '#f59e0b'],
            ['skill' => 'Writing', 'percentage' => min(92, max(40, (int)($overallCompletionPercentage * 0.85 + 38))), 'color' => '#8b5cf6'],
        ];

        // Super Admin Specific Metrics
        $superAdminData = null;
        if ($isSuperAdmin) {
            $totalTenants = \App\Models\Tenant::count();
            $tenantsList = \App\Models\Tenant::withCount([
                'users as students_count' => function($q) { $q->where('role', 'student'); },
                'users as staff_count' => function($q) { $q->where('role', 'staff'); }
            ])->get();

            $totalPackages = \App\Models\Package::count();
            $totalProperties = \App\Models\Property::count();

            $superAdminData = [
                'total_tenants' => $totalTenants,
                'tenants_list' => $tenantsList,
                'total_packages' => $totalPackages,
                'total_properties' => $totalProperties,
            ];
        }

        return response()->json([
            'total_students' => $totalStudents,
            'total_staff' => $totalStaff,
            'active_courses' => $activeCourses,
            'overall_completion_rate' => $overallCompletionPercentage,
            'active_today' => $activeTodayCount,
            'top_performers' => $topPerformers,
            'recent_activities' => $recentActivities,
            'upcoming_live_classes' => $upcomingLiveClasses,
            'recent_announcements' => $recentAnnouncements,
            'weekly_activity' => $weeklyActivity,
            'skill_breakdown' => $skillBreakdown,
            'super_admin_data' => $superAdminData,
        ]);
    }

    /**
     * Record a student's interactive activity (MCQ, Match, Flashcards, Assessment)
     * for XP tracking and streak counting.
     */
    public function recordActivity(Request $request)
    {
        $validated = $request->validate([
            'content_id' => 'nullable|integer',
            'activity_type' => 'required|string|in:mcq,match,flashcard,assessment',
            'score' => 'required|integer|min:0',
            'total' => 'required|integer|min:1',
        ]);

        $user = $request->user();
        $userId = $user->id;

        // Calculate XP based on activity type and performance
        $xpEarned = 0;
        switch ($validated['activity_type']) {
            case 'mcq':
                $xpEarned = $validated['score'] * 50; // 50 XP per correct answer
                break;
            case 'match':
                $xpEarned = $validated['score'] * 25; // 25 XP per correct match
                break;
            case 'flashcard':
                $xpEarned = 30; // flat 30 XP for reviewing flashcards
                break;
            case 'assessment':
                $xpEarned = (int) round(($validated['score'] / max($validated['total'], 1)) * 200);
                break;
        }

        // Record the activity in user_course_progress as a general activity log entry
        // This feeds into the streak calculation (calculateStreak uses completed_at dates)
        DB::table('user_course_progress')->insert([
            'user_id' => $userId,
            'chapter_id' => null,
            'status' => 'activity_completed',
            'completed_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Recalculate stats and save to users table
        self::recalculateUserStats($userId);

        return response()->json([
            'success' => true,
            'xp_earned' => $xpEarned,
            'activity_type' => $validated['activity_type'],
            'message' => "Activity recorded! You earned {$xpEarned} XP.",
        ]);
    }

    /**
     * Reusable helper to recalculate user stats and save them to the users table.
     */
    public static function recalculateUserStats($userId)
    {
        $user = \App\Models\User::find($userId);
        if (!$user) return null;

        $completedChaptersQuery = DB::table('user_course_progress')
            ->where('user_id', $userId)
            ->where('status', 'completed')
            ->whereNotNull('chapter_id');
        if (\Schema::hasColumn('user_course_progress', 'content_id')) {
            $completedChaptersQuery->whereNull('content_id');
        }
        $completedChapters = $completedChaptersQuery->distinct('chapter_id')->count('chapter_id');

        $totalAttempts = DB::table('user_assessment_attempts')
            ->where('user_id', $userId)
            ->count();

        $passedAttempts = DB::table('user_assessment_attempts')
            ->where('user_id', $userId)
            ->where('passed', true)
            ->count();

        // Calculate streak
        $progressDates = DB::table('user_course_progress')
            ->where('user_id', $userId)
            ->whereNotNull('completed_at')
            ->pluck('completed_at')
            ->map(function ($date) {
                return date('Y-m-d', strtotime($date));
            })
            ->toArray();

        $attemptDates = DB::table('user_assessment_attempts')
            ->where('user_id', $userId)
            ->pluck('attempted_at')
            ->map(function ($date) {
                return date('Y-m-d', strtotime($date));
            })
            ->toArray();

        $allDates = array_unique(array_merge($progressDates, $attemptDates));
        rsort($allDates);

        $streak = 0;
        if (!empty($allDates)) {
            $today = date('Y-m-d');
            $yesterday = date('Y-m-d', strtotime('-1 day'));
            $mostRecent = $allDates[0];
            if ($mostRecent === $today || $mostRecent === $yesterday) {
                $currentDate = $mostRecent;
                foreach ($allDates as $date) {
                    if ($date === $currentDate) {
                        $streak++;
                        $currentDate = date('Y-m-d', strtotime($currentDate . ' -1 day'));
                    } else {
                        break;
                    }
                }
            }
        }

        $activityCompletions = DB::table('user_course_progress')
            ->where('user_id', $userId)
            ->where('status', 'activity_completed')
            ->count();

        $xpPoints = 1250 + ($completedChapters * 100) + ($passedAttempts * 200) + ($totalAttempts * 50) + ($streak * 25) + ($activityCompletions * 75);
        $gems = 85 + ($completedChapters * 15) + ($passedAttempts * 30) + ($streak * 5) + ($activityCompletions * 10);

        if (\Schema::hasColumn('users', 'xp')) {
            $user->xp = $xpPoints;
        }
        if (\Schema::hasColumn('users', 'gems')) {
            $user->gems = $gems;
        }
        // Save if user attributes were updated
        if ($user->isDirty()) {
            $user->save();
        }

        return [
            'xp' => $xpPoints,
            'gems' => $gems,
            'streak' => $streak
        ];
    }
}
