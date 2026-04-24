<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Property extends Model
{
    protected $fillable = [
        'tenant_id',
        'property_code',
        'property_name',
        'location',
        'address',
        'max_users',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'max_users' => 'integer',
    ];

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function packages(): BelongsToMany
    {
        return $this->belongsToMany(Package::class, 'property_packages')
            ->withPivot(['id', 'course_id', 'start_date', 'end_date', 'is_active', 'learning_mode_ids'])
            ->withTimestamps();
    }
}
