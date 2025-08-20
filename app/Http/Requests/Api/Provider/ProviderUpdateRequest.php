<?php

namespace App\Http\Requests\Api\Provider;

use Illuminate\Foundation\Http\FormRequest;

class ProviderUpdateRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     *
     * @return bool
     */
    public function authorize()
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array
     */
    public function rules()
    {
        return [
            'document_url' => 'string|nullable',
            'image_url' => 'string|nullable',
            'about' => 'required|string',
            'approx_price' => 'required|numeric',
            'address' => 'required|string',
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'categories' => 'required|array|exists:categories,id',
        ];
    }
}
