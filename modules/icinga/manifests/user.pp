class icinga::user {
    include nagios::group
    # FIXME: where does the dialout user group come from?
    # It should be included here somehow

    group { 'icinga':
        ensure => present,
        name   => 'icinga',
    }

    user { 'icinga':
        name       => 'icinga',
        home       => '/home/icinga',
        gid        => 'icinga',
        system     => true,
        managehome => false,
        shell      => '/bin/false',
        require    => [ Group['icinga'], Group['nagios'] ],
        groups     => [ 'dialout', 'nagios' ],
    }
}
