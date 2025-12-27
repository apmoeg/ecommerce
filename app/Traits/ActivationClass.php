<?php

namespace App\Traits;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Session;

trait ActivationClass
{
    public function dmvf($request)
    {
        if (self::is_local()) {
            Session::put(base64_decode('cHVyY2hhc2Vfa2V5'), $request[base64_decode('cHVyY2hhc2Vfa2V5')]);//pk
            Session::put(base64_decode('dXNlcm5hbWU='), $request[base64_decode('dXNlcm5hbWU=')]);//un
            return base64_decode('c3RlcDM=');//s3
        } else {
            $remove = array("http://", "https://", "www.");
            $url = str_replace($remove, "", url('/'));

            $post = [
                base64_decode('dXNlcm5hbWU=') => $request[base64_decode('dXNlcm5hbWU=')],//un
                base64_decode('cHVyY2hhc2Vfa2V5') => $request[base64_decode('cHVyY2hhc2Vfa2V5')],//pk
                base64_decode('c29mdHdhcmVfaWQ=') => base64_decode(env(base64_decode('U09GVFdBUkVfSUQ='))),//sid
                base64_decode('ZG9tYWlu') => $url
            ];

            try {
                $response = Http::post(base64_decode('aHR0cHM6Ly9saWNlbnNlLmh1Z291cy5jb20='), $post)->json();
                $status = $response['active'] ?? base64_encode(1);
                if (base64_decode($status)) {
                    Session::put(base64_decode('cHVyY2hhc2Vfa2V5'), $request[base64_decode('cHVyY2hhc2Vfa2V5')]);//pk
                    Session::put(base64_decode('dXNlcm5hbWU='), $request[base64_decode('dXNlcm5hbWU=')]);//un
                    return base64_decode('c3RlcDM=');//s3
                } else {
                    return base64_decode('aHR0cHM6Ly9odWdvdXMuY29t');
                }
            } catch (\Exception $exception) {
                Session::put(base64_decode('cHVyY2hhc2Vfa2V5'), $request[base64_decode('cHVyY2hhc2Vfa2V5')]);//pk
                Session::put(base64_decode('dXNlcm5hbWU='), $request[base64_decode('dXNlcm5hbWU=')]);//un
                return base64_decode('c3RlcDM=');//s3
            }
        }
    }

    public function actch()
    {
        if (self::is_local()) {
            return response()->json([
                'active' => 1
            ]);
        } else {
            $remove = array("http://", "https://", "www.");
            $url = str_replace($remove, "", url('/'));

            $post = [
                base64_decode('dXNlcm5hbWU=') => env(base64_decode('QlVZRVJfVVNFUk5BTUU=')),//un
                base64_decode('cHVyY2hhc2Vfa2V5') => env(base64_decode('UFVSQ0hBU0VfQ09ERQ==')),//pk
                base64_decode('c29mdHdhcmVfaWQ=') => base64_decode(env(base64_decode('U09GVFdBUkVfSUQ='))),//sid
                base64_decode('ZG9tYWlu') => $url,
            ];
            try {
                $response = Http::post(base64_decode('aHR0cHM6Ly9saWNlbnNlLmh1Z291cy5jb20='), $post)->json();
                $status = $response['active'] ?? base64_encode(1);

                return response()->json([
                    'active' => (int)base64_decode($status)
                ]);

            } catch (\Exception $exception) {
                return response()->json([
                    'active' => 1
                ]);
            }
        }
    }

    public function is_local(): bool
    {
        $whitelist = array(
            '127.0.0.1',
            '::1'
        );

        if (!in_array(request()->ip(), $whitelist)) {
            return false;
        }

        return true;
    }
}
