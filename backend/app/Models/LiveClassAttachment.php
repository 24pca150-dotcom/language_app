<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

class LiveClassAttachment extends Model
{
    use HasFactory;

    protected $fillable = [
        'live_class_id',
        'title',
        'file_type',
        'file_path',
        'original_name',
        'file_extension',
        'file_size',
        'uploaded_by',
    ];

    protected $appends = ['file_url'];

    public function getFileUrlAttribute()
    {
        if (!$this->file_path) return null;
        return Storage::disk('public')->url($this->file_path);
    }

    public function liveClass()
    {
        return $this->belongsTo(LiveClass::class);
    }

    public function uploader()
    {
        return $this->belongsTo(User::class, 'uploaded_by');
    }
}
