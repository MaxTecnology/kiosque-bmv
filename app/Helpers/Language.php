<?php

namespace App\Helpers;

use App\Models\Setting;

class Language
{
    private $languageCode;

    public $dictionary = [];
    public $fallback;

    public function __construct($languageCode)
    {
        $this->languageCode = $languageCode ? $languageCode : "en";
        $this->fallback = json_decode(json_encode([
            "en" => [
                "appointment_new_title" => "New Appointment",
                "appointment_new_body" => "You have recieved new appointment for service",
                "appointment_rescheduled_title" => "Appointment Rescheduled",
                "appointment_rescheduled_body" => "Your appointment with provider is rescheduled",
                "appointment_cancelled_title" => "Appointment Cancelled",
                "appointment_cancelled_body" => "Client has cancelled the appointment",
                "appointment_rejected_title" => "Appointment Rejected",
                "appointment_rejected_body" => "Provider has rejected the appointment",
                "appointment_accepted_title" => "Appointment Accepted",
                "appointment_accepted_body" => "Provider has accepted the appointment",
                "appointment_ongoing_title" => "Appointment Started",
                "appointment_ongoing_body" => "Provider has started the appointment",
                "appointment_complete_title" => "Appointment Complete",
                "appointment_complete_body" => "Your appointment with provider is complete",
                "chat_new_message" => "New message",
                "chat_new_body" => "You have a new message from "
            ]
        ]));

        try {
            $this->dictionary = json_decode(Setting::where('key', 'language')->get()->first()->value);
        } catch (\Exception $exception) {
            $this->dictionary = $this->fallback;
        }
    }

    public function get($key)
    {
        $languageCode = $this->languageCode;
        $languageCode = isset($this->dictionary->$languageCode) ? $languageCode : "en";
        try {
            return $this->dictionary->$languageCode->$key;
        } catch (\Exception $exception) {
            return $this->fallback->en->$key;
        }
    }
}