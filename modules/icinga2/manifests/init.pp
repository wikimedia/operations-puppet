
class icinga2() {
    $ichinga2_server = hiera('icinga2_server', false)

    group { 'nagios':
        ensure    => present,
        name      => 'nagios',
        system    => true,
        allowdupe => false,
    }

    group { 'icinga2':
        ensure => present,
        name   => 'icinga2',
    }

    user { 'icinga2':
        name       => 'icinga2',
        home       => '/home/icinga2',
        gid        => 'icinga',
        system     => true,
        managehome => false,
        shell      => '/bin/false',
        require    => [ Group['icinga'], Group['nagios'] ],
        groups     => [ 'nagios' ],
    }

    if $ichinga2_server {
      include ::icinga2:icinga2_server
    }

    package { 'nagios-nrpe-plugin':
        ensure  => present,
    }
}
