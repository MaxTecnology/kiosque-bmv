<?php

namespace App\Http\Requests\Api\Provider;

use Illuminate\Foundation\Http\FormRequest;

class AppointmentUpdateRequest extends FormRequest
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
            'status' => 'sometimes|in:accepted,onway,ongoing,complete,rejected',
            'date' => 'sometimes|date',
            'time_from' => 'required_with:date|date_format:H:i',
            'time_to' => 'required_with:date|date_format:H:i'
        ];
    }
}
