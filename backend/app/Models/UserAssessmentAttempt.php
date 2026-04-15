<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserAssessmentAttempt extends Model
{
    protected $fillable = [
        'user_id',
        'assessment_id',
        'score',
        'passed',
        'attempted_at',
    ];

    protected $casts = [
        'score' => 'decimal:2',
        'passed' => 'boolean',
        'attempted_at' => 'datetime',
    ];

    public function assessment(): BelongsTo
    {
        return $this->belongsTo(Assessment::class);
    }
}
