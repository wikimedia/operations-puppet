# http://apt.wikimedia.org/wikimedia/
class role::aptrepo::wikimedia {

    $basedir = '/srv/wikimedia'

    class { '::aptrepo':
        basedir       => $basedir,
        incomingconf  => 'incoming-wikimedia',
        incominguser  => 'root',
        # Allow wikidev users to upload to /srv/wikimedia/incoming
        incominggroup => 'wikidev',
    }

    file { "${basedir}/conf/distributions":
        ensure => present,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/aptrepo/distributions-wikimedia',
    }

    include role::backup::host
    backup::set { 'srv-wikimedia': }

    include aptrepo::rsync
    
    # disable autoconfigured EUI64 addresses (but not router advertisements)
    sysctl::parameters { 'disable_eui64':
        values  => { 'net.ipv6.conf.eth0.autoconf' => '0', },
    }

}
