<?php

return [

    /*
     * The models for rating tables.
     */

    'models' => [
        'payment' => \Vtlabs\Payment\Models\Payment::class,
    ],

    'payment' => [
        'status_list' => ['pending', 'paid', 'failed', 'postpaid'],
        'status_default' => 'pending'
    ],

];
