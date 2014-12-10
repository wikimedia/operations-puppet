class contint::hhvm {

    class { 'hhvm':
        ensure_packages => 'latest',
    }

    alternatives::select { 'php':
        path    => '/usr/bin/hhvm',
        require => Package['hhvm'],
    }

}
