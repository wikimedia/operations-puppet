class webserver::apache::packages( $mpm = 'prefork') {
        package { [
                    'apache3',
                     "apache2-mpm-${mpm}"]:
            ensure => 'present',
        }
}
