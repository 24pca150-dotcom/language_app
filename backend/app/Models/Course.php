<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Course extends Model
{
    protected $fillable = [
        'name',
        'code',
        'no_of_levels',
        'description',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'no_of_levels' => 'integer',
    ];

    /**
     * Auto-generate course code before creating.
     */
    protected static function boot()
    {
        parent::boot();

        static::creating(function ($course) {
            if (empty($course->code)) {
                $last = static::orderBy('id', 'desc')->first();
                $nextId = $last ? $last->id + 1 : 1;
                $course->code = 'CRS-' . str_pad($nextId, 5, '0', STR_PAD_LEFT);
            }
        });
    }

    public function levels(): HasMany
    {
        return $this->hasMany(Level::class)->orderBy('sort_order');
    }
}
