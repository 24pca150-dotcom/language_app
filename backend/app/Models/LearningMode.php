<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LearningMode extends Model
{
    protected $fillable = [
        'name',
        'code',
        'description',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];
}
