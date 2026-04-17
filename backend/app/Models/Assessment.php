<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Assessment extends Model
{
    protected $fillable = [
        'level_id',
        'chapter_id',
        'sub_chapter_id',
        'title',
        'description',
        'pass_percentage',
        'is_mandatory',
        'duration_minutes',
        'allow_restart',
        'review_mode',
        'activity_type',
        'prelude_content',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'is_mandatory' => 'boolean',
        'allow_restart' => 'boolean',
        'pass_percentage' => 'decimal:2',
        'duration_minutes' => 'integer',
    ];

    public function level(): BelongsTo
    {
        return $this->belongsTo(Level::class);
    }

    public function chapter(): BelongsTo
    {
        return $this->belongsTo(Chapter::class);
    }

    public function subChapter(): BelongsTo
    {
        return $this->belongsTo(SubChapter::class);
    }

    public function questions(): HasMany
    {
        return $this->hasMany(AssessmentQuestion::class)->orderBy('sort_order');
    }
}
