# == Class authdns::monitoring
# Monitoring checks for authdns, specific to Wikimedia setup
#
class authdns::monitoring {
    # This monitors the specific authdns server directly via
    #  its own fqdn, which won't generally be one of the listener
    #  addresses we really care about.  This gives a more-direct
    #  view of reality, though, as the mapping of listener addresses
    #  to real hosts could be fluid due to routing/anycast.
    monitoring::service { 'auth dns':
        description   => 'Auth DNS',
        check_command => 'check_dns!www.wikipedia.org',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/DNS',
    }

    # This is a local NRPE check to validate that the authdns server's config
    # and zonefiles still load.  This is an important gaurd against e.g.
    # puppet-deploying an invalid configuration, which might otherwise only
    # cause a single failed puppet run (until someone tries to deploy DNS
    # changes and gets blocked).
    file { '/usr/local/lib/nagios/plugins/check_gdnsd_checkconf':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/authdns/check_gdnsd_checkconf',
    }

    nrpe::monitor_service { 'gdnsd_checkconf':
        description  => 'gdnsd checkconf',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_gdnsd_checkconf',
        require      => File['/usr/local/lib/nagios/plugins/check_gdnsd_checkconf'],
    }
}
