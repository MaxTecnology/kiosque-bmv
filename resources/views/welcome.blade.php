@extends('layouts.welcome')

@section('content')
    <div class="title m-b-md">
        @if(env('APP_LOGO'))
            <div><img src="{{env('APP_LOGO')}}" /></div>
        @endif
        {{ config('app.name') }}
    </div>
@endsection