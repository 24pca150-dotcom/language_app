<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\Pivot;

class CoursePackageLevel extends Pivot
{
    protected $table = 'course_package_levels';

    protected $fillable = [
        'course_id',
        'package_id',
        'level_id',
        'is_mandatory',
        'is_active',
    ];

    protected $casts = [
        'is_mandatory' => 'boolean',
        'is_active' => 'boolean',
    ];
}
