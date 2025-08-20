<?php

if (!function_exists('__trans_choice')) {
    /**
     * Translates the given message based on a count from json key.
     *
     * @param $key
     * @param $number
     * @param array $replace
     * @param null $locale
     * @return string
     */
    function __trans_choice($key, $number, array $replace = [], $locale = null)
    {
        return trans_choice(__($key), $number, $replace, $locale);
    }
}