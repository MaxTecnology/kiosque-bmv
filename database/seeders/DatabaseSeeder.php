<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Database\Seeders\UsersTableSeeder;
use Database\Seeders\SettingTableSeeder;
use Database\Seeders\PaymentMethodTableSeeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     *
     * @return void
     */
    public function run()
    {
        $this->call(UsersTableSeeder::class);
        $this->call(SettingTableSeeder::class);
        $this->call(PaymentMethodTableSeeder::class);
    }
}
