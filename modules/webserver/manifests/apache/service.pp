class webserver::apache::service {
    service{ 'apache2':
        ensure => 'running',
    }
}
