<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class UpdateContentRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'name'           => 'required|string|max:255',
            'chapter_ids'    => 'nullable|array',
            'chapter_ids.*'  => 'exists:chapters,id',
            'sort_order'     => 'integer',
            'is_active'      => 'boolean',
            'text_content'   => 'nullable|string',
            'urls'           => 'nullable|array',
            'urls.*'         => 'nullable|string',
            'attachments'    => 'nullable|array',
            'attachments.*'  => 'nullable|array',
        ];
    }
}
