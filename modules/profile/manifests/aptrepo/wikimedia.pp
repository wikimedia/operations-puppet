# http://apt.wikimedia.org/wikimedia/
class profile::aptrepo::wikimedia (
    $primary_server = hiera('install_server'),
    $secondary_server = hiera('install_server_failover'),
){
    $basedir = '/srv/wikimedia'

    class { '::aptrepo':
        basedir       => $basedir,
        incomingconf  => 'incoming-wikimedia',
        incominguser  => 'root',
        # Allow wikidev users to upload to /srv/wikimedia/incoming
        incominggroup => 'wikidev',
    }

    file { "${basedir}/conf/distributions":
        ensure       => present,
        mode         => '0444',
        owner        => 'root',
        group        => 'root',
        source       => 'puppet:///modules/aptrepo/distributions-wikimedia',
        validate_cmd => '/usr/bin/python -c "import apt_pkg; f=\'%\'; list(apt_pkg.TagFile(f))"',
    }

    include ::profile::backup::host
    backup::set { 'srv-wikimedia': }

    class { 'aptrepo::rsync':
        primary_server   => $primary_server,
        secondary_server => $secondary_server,
    }
}
