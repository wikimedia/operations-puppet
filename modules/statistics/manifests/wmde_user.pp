class statistics::wmde::user($home = '/srv/analytics-wmde') {

    $user = 'analytics-wmde'

    group { $user:
        ensure => present,
        name   => $user,
    }

    user { $user:
        ensure     => present,
        shell      => '/bin/bash',
        managehome => false,
        home       => $home,
        system     => true,
        require    => Group[$user],
    }

}
