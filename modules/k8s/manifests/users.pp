class k8s::users {
    group { 'kubernetes':
        ensure => present,
        system => true,
    }

    user { 'kubernetes':
        ensure     => present,
        shell      => '/bin/false',
        system     => true,
        managehome => false,
        groups     => ['ssl-cert'],
    }
}
