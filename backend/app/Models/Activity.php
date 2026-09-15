<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Activity extends Model
{
    protected $fillable = [
        'tenant_id',
        'course_id',
        'title',
        'type',
        'data_json',
        'created_by'
    ];

    protected $casts = [
        'data_json' => 'array',
    ];

    public function course()
    {
        return $this->belongsTo(Course::class);
    }

    public function tenant()
    {
        return $this->belongsTo(Tenant::class);
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
