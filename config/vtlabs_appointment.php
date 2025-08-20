<?php

return [

    /*
     * The models for rating tables.
     */

    'models' => [
        'appointment' => \Vtlabs\Appointment\Models\Appointment::class,
    ],

    'appointment' => [
        'status_list' => ['pending', 'accepted', 'onway', 'ongoing', 'complete', 'cancelled', 'rejected'],
        'status_default' => 'pending'
    ],

];
