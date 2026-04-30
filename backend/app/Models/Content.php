<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Content extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'sort_order',
        'is_active',
        'text_content',
        'external_url',
        'image',
        'video',
        'pdf',
        'doc',
        'xlsx',
        'ppt'
    ];

    protected $casts = [
        'is_active'    => 'boolean',
        'sort_order'   => 'integer',
        'external_url' => 'array',
        'image'        => 'array',
        'video'        => 'array',
        'pdf'          => 'array',
        'doc'          => 'array',
        'xlsx'         => 'array',
        'ppt'          => 'array',
    ];

    protected $appends = ['urls', 'image_list', 'video_list', 'pdf_list', 'doc_list', 'xlsx_list', 'ppt_list'];

    public function getUrlsAttribute(): array { return $this->external_url ?? []; }
    public function getImageListAttribute(): array { return $this->image ?? []; }
    public function getVideoListAttribute(): array { return $this->video ?? []; }
    public function getPdfListAttribute(): array { return $this->pdf ?? []; }
    public function getDocListAttribute(): array { return $this->doc ?? []; }
    public function getXlsxListAttribute(): array { return $this->xlsx ?? []; }
    public function getPptListAttribute(): array { return $this->ppt ?? []; }

    public function chapters(): \Illuminate\Database\Eloquent\Relations\BelongsToMany
    {
        return $this->belongsToMany(Chapter::class, 'content_chapters');
    }
}
