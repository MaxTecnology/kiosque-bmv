<?php

namespace App\Http\Requests\Api\Customer;

use Illuminate\Foundation\Http\FormRequest;

class AppointmentCreateRequest extends FormRequest
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
            'provider_id' => 'required|exists:provider_profiles,id',
	        'category_id' => 'required|exists:categories,id',
            'address_id' => 'required|exists:addresses,id',
            'date' => 'required|date',
            'time_from' => 'required|date_format:H:i',
            'time_to' => 'required|date_format:H:i',
            'notes' => 'string|nullable'
        ];
    }
}
