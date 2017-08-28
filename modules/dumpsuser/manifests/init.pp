class dumpsuser {
    $user = 'dumpsgen'
    $group = 'dumpsgen'

    user { $user:
        uid        => 400,
        gid        => $group,
        home       => "/var/lib/${user}",
        shell      => '/bin/bash',
        managehome => true,
        system     => true,
    }

    group { $group:
        ensure => present,
        gid    => 400,
        system => true,
    }
}
