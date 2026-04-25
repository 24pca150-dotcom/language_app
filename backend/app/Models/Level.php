<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Level extends Model
{
    protected $fillable = [

        'name',
        'code',
        'description',
        'objective_listening',
        'objective_speaking',
        'objective_reading',
        'objective_writing',
        'estimated_hours',
        'sort_order',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'estimated_hours' => 'decimal:2',
        'sort_order' => 'integer',
    ];




    public function assessments(): HasMany
    {
        return $this->hasMany(Assessment::class);
    }

    public function packages(): BelongsToMany
    {
        return $this->belongsToMany(Package::class, 'course_package_levels')
            ->withPivot(['id', 'is_active'])
            ->withTimestamps();
    }
}
