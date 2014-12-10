class contint::hhvm {

    include ::hhvm

    alternatives::select { 'php':
        path    => '/usr/bin/hhvm',
        require => Package['hhvm'],
    }

}
