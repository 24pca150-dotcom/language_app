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
        'cover_image',
        'data_json',
        'created_by'
    ];

    protected $casts = [
        'data_json' => 'array',
    ];

    /**
     * Default mobile game cover for an activity type (files in storage/app/public/game-covers).
     * Keep in sync with GAME_COVER_FILES in the web Activity Builder.
     */
    public static function defaultCoverFor(?string $type): ?string
    {
        $key = str_replace('-', '_', strtolower((string) $type));
        $key = match ($key) {
            'multiple_choice' => 'mcq',
            'cloud_match' => 'match',
            'canvas', 'custom_canvas' => 'custom',
            default => $key,
        };

        // Served through the /storage route so the CORS headers reach the mobile (Flutter web) app
        foreach (['jpg', 'svg'] as $ext) {
            if (file_exists(storage_path("app/public/game-covers/{$key}.{$ext}"))) {
                return url("storage/game-covers/{$key}.{$ext}");
            }
        }

        return null;
    }

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
