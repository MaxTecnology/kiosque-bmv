<?php

namespace App\Http\Requests\Api\Customer;

use Illuminate\Foundation\Http\FormRequest;

class ProviderProfileListRequest extends FormRequest
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
            'category' => 'required|exists:categories,id',
            'lat' => 'required|numeric',
            'long' => 'required|numeric'
        ];
    }
}
