# Class: role::mirrors
#
# A role class used to setup our mirrors server.

class role::mirrors {
    system::role { 'mirrors':
        description => 'Mirrors server',
    }

    include ::profile::standard
    include mirrors::serve
    include mirrors::tails
    include ::profile::base::firewall

    include mirrors::ubuntu
    nrpe::monitor_service {'check_ubuntu_mirror':
        description  => 'Ubuntu mirror in sync with upstream',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_apt_mirror /srv/mirrors/ubuntu',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Mirrors',
    }

    include mirrors::debian
    nrpe::monitor_service {'check_debian_mirror':
        description  => 'Debian mirror in sync with upstream',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_apt_mirror /srv/mirrors/debian',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Mirrors',
    }

    ferm::service { 'mirrors_http':
        proto => 'tcp',
        port  => '(http https)'
    }
    ferm::service { 'mirrors_rsync':
        proto => 'tcp',
        port  => '873',
    }
    ferm::service { 'mirrors_ssh':
        proto  => 'tcp',
        port   => 'ssh',
        # syncproxy2.wna.debian.org; ferm can't do both IPv4/IPv6 with @resolve
        srange => '(149.20.4.16 2001:4f8:1:c::16)',
    }
}
