class contint::hhvm {

    class { '::hhvm':
        packages_ensure => 'latest',
    }

    alternatives::select { 'php':
        path    => '/usr/bin/hhvm',
        require => Package['hhvm'],
    }

}
