<?php

namespace Database\Seeders;

use Carbon\Carbon as Carbon;
use Illuminate\Database\Seeder;

use Vtlabs\Core\Models\User\User;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\Models\Role;

class UsersTableSeeder extends Seeder
{

    /**
     * Run the database seed.
     *
     * @return void
     */
    public function run()
    {
        // users
        $users = [
            [
                'name' => 'Admin',
                'email' => 'admin@example.com',
                'password' => bcrypt('admin'),
                'active' => true,                
                'mobile_number' => '8888888888',
                'mobile_verified' => true,
                'created_at' => Carbon::now(),
                'updated_at' => Carbon::now(),
            ]
        ];
        DB::table('users')->insert($users);

        // create role
        $adminRole = Role::create(['name' => 'admin', 'guard_name' => 'api']);
        $customerRole = Role::create(['name' => 'customer', 'guard_name' => 'api']);
        $vendorRole = Role::create(['name' => 'vendor', 'guard_name' => 'api']);
        $deliveryRole = Role::create(['name' => 'delivery', 'guard_name' => 'api']);

        // attach role to user
        $data = [
            'admin@example.com' => ['admin']
        ];

        foreach ($data as $email => $role) {
            $user = User::whereEmail($email)->first();

            if (!$user) continue;

            $role = !is_array($role) ? [$role] : $role;

            $user->assignRole($role);
        }
    }
}
