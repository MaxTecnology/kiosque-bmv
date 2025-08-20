<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Vtlabs\Doctor\Models\Hospital;
use Vtlabs\Payment\Models\PaymentMethod;

class PaymentMethodTableSeeder extends Seeder
{
    public function run()
    {
        $paymentMethods = [
            [
                'slug' => 'cod',
                'title' => ['en' => 'Cash On Delivery'],
                'enabled' => true,
                'type' => 'postpaid'
            ]
        ];
        
        foreach($paymentMethods as $paymentMethod) {
            PaymentMethod::create($paymentMethod);
        }
    }
}
