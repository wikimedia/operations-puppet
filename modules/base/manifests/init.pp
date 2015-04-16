class base {
    include apt

    if ($::realm == 'labs') {
        include apt::unattendedupgrades,
            apt::noupgrade
    }

    file { '/usr/local/sbin':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    if ($::realm == 'labs') {
        # For labs, use instanceid.domain rather than the fqdn
        # to ensure we're always using a unique certname.
        # $::ec2id is a fact that queries the instance metadata
        if($::ec2id == '') {
            fail('Failed to fetch instance ID')
        }
        $certname = "${::ec2id}.${::domain}"

        # Labs instances /var is quite small, provide our own default
        # to keep less records (T71604).
        file { '/etc/default/acct':
            ensure => present,
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => 'puppet:///modules/base/labs-acct.default',
        }

        if $::operatingsystem == 'Debian' {
            # Turn on idmapd by default
            file { '/etc/default/nfs-common':
                ensure => present,
                owner  => 'root',
                group  => 'root',
                mode   => '0444',
                source => 'puppet:///modules/base/labs/nfs-common.default',
            }
        }
    } else {
        $certname = undef
    }

    $puppetmaster =  $::realm ? {
        'labs'  => 'virt1000.wikimedia.org',
        default => 'puppet',
    }

    class { 'base::puppet':
        server   => $puppetmaster,
        certname => $certname,
    }

    include passwords::root
    include base::grub
    include base::resolving
    include base::remote-syslog
    include base::sysctl
    include ::motd
    include base::standard-packages
    include base::environment
    include base::phaste
    include base::screenconfig
    include ssh::client
    include ssh::server
    include role::salt::minions
    include role::trebuchet
    include nrpe


    # include base::monitor::host.
    # if $nagios_contact_group is set, then use it
    # as the monitor host's contact group.

    $group_contact = $::nagios_contact_group ? {
        undef   => 'admins',
        default => $::nagios_contact_group,
    }

    class { 'base::monitoring::host':
        contact_group => $group_contact,
    }

    # CA for the new ldap-eqiad/ldap-codfw ldap servers, among
    # other things.
    include certificates::globalsign_ca
    # TODO: Kill the old wmf_ca
    include certificates::wmf_ca
    include certificates::wmf_ca_2014_2017
}
