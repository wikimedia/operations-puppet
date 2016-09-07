# Class: role::mirrors
#
# A role class used to setup our mirrors server.

class role::mirrors {
    system::role { 'role::mirrors':
        description => 'Mirrors server',
    }

    include mirrors::serve
    include mirrors::tails

    include mirrors::ubuntu
    nrpe::monitor_service {'check_ubuntu_mirror':
        description  => 'Ubuntu mirror in sync with upstream',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_apt_mirror /srv/mirrors/ubuntu',
    }

    include mirrors::debian
    nrpe::monitor_service {'check_debian_mirror':
        description  => 'Debian mirror in sync with upstream',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_apt_mirror /srv/mirrors/debian',
    }

    ferm::service { 'mirrors_http':
        proto => 'tcp',
        port  => '(http https)'
    }
}
