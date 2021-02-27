class mailman3 (
    String $host,
    String $db_host,
    String $db_password,
    String $db_password_web,
    String $api_password,
    String $web_secret,
    String $archiver_key,
    String $service_ensure = 'running',
) {

    class { '::mailman3::listserve':
        service_ensure => $service_ensure,
        db_host        => $db_host,
        db_password    => $db_password,
        api_password   => $api_password,
    }

    class { '::mailman3::web':
        host           => $host,
        service_ensure => $service_ensure,
        db_host        => $db_host,
        db_password    => $db_password_web,
        api_password   => $api_password,
        secret         => $web_secret,
        archiver_key   => $archiver_key
    }

    class { '::mailman3::hyperkitty':
        archiver_key   => $archiver_key
    }

}
