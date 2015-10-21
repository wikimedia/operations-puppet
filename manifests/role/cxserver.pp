# vim: set ts=4 et sw=4:

class role::cxserver {
    system::role { 'role::cxserver':
        description => 'content translation server'
    }

    include ::passwords::cxserver
    $yandex_api_key = $::passwords::cxserver::yandex_api_key
    $jwt_secret = $::passwords::cxserver::jwt_secret

    class { '::cxserver':
        yandex_api_key => $yandex_api_key,
        jwt_secret => $jwt_secret,
    }

    ferm::service { 'cxserver_http':
        proto => 'tcp',
        port  => $::cxserver::port,
    }

    monitoring::service { 'cxserver':
        description   => 'cxserver',
        check_command => "check_http_on_port!${::cxserver::port}",
    }
}
