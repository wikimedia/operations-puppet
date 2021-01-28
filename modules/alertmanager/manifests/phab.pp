class alertmanager::phab (
    Stdlib::HTTPSUrl $url,
    String $username,
    String $token,
    String $listen_host = '::',
    Stdlib::Port $listen_port = 8292,
) {
    require_package('phalerts')

    service { 'phalerts':
        ensure  => running,
    }

    base::service_auto_restart { 'phalerts': }

    file { '/etc/default/phalerts':
        ensure    => present,
        owner     => 'phalerts',
        group     => 'root',
        mode      => '0440',
        content   => template('alertmanager/phalerts.default.erb'),
        notify    => Service['phalerts'],
        show_diff => false,
    }
}
