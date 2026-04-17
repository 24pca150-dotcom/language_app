<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserCourseProgress extends Model
{
    protected $table = 'user_course_progress';

    protected $fillable = [
        'user_id',
        'course_id',
        'level_id',
        'chapter_id',
        'sub_chapter_id',
        'status',
        'score',
        'completed_at',
    ];

    protected $casts = [
        'completed_at' => 'datetime',
        'score' => 'decimal:2',
    ];

    public function level()
    {
        return $this->belongsTo(Level::class);
    }

    public function chapter()
    {
        return $this->belongsTo(Chapter::class);
    }

    public function subChapter()
    {
        return $this->belongsTo(SubChapter::class);
    }}
