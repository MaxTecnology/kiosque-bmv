<?php

namespace App\Providers;

use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;

class EventServiceProvider extends ServiceProvider
{
    /**
     * The event listener mappings for the application.
     *
     * @var array
     */
    protected $listen = [
        // Login::class => [LoginListener::class],
        // Logout::class => [LogoutListener::class],
        // Registered::class => [RegisteredListener::class],
        // SocialLogin::class => [SocialLoginListener::class],
	    // NewAppointment::class => [NewAppointmentListener::class],
	    // UpdateAppointment::class => [UpdateAppointmentListener::class]
    ];

    /**
     * Register any events for your application.
     *
     * @return void
     */
    public function boot()
    {
        parent::boot();

        //
    }
}
