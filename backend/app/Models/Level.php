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
        'course_id',
        'name',
        'code',
        'description',
        'estimated_hours',
        'sort_order',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'estimated_hours' => 'decimal:2',
        'sort_order' => 'integer',
    ];

    public function course(): BelongsTo
    {
        return $this->belongsTo(Course::class);
    }

    public function chapters(): HasMany
    {
        return $this->hasMany(Chapter::class)->orderBy('sort_order');
    }

    public function assessment(): HasOne
    {
        return $this->hasOne(Assessment::class);
    }

    public function packages(): BelongsToMany
    {
        return $this->belongsToMany(Package::class, 'course_package_levels')
            ->withPivot(['id', 'is_active'])
            ->withTimestamps();
    }
}
