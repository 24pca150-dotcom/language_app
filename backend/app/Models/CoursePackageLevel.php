<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\Pivot;

class CoursePackageLevel extends Pivot
{
    protected $table = 'course_package_levels';

    protected $fillable = [
        'package_id',
        'level_id',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];
}
