class base {
    include apt
    include apt::update

    if ($::realm == 'labs') {
        include apt::unattendedupgrades,
            apt::noupgrade
    }

    include base::tcptweaks

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
        # to keep less records (bug 69604).
        file { '/etc/default/acct':
            ensure => present,
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => 'puppet:///modules/base/labs-acct.default',
        }
    } else {
        $certname = undef
    }

    class { 'base::puppet':
        server   => $::realm ? {
            'labs'  => $::site ? {
                'eqiad' => 'virt1000.wikimedia.org',
            },
            default => 'puppet',
        },
        certname => $certname,
    }

    include passwords::root,
        base::grub,
        base::resolving,
        base::remote-syslog,
        base::sysctl,
        base::motd,
        base::standard-packages,
        base::environment,
        base::platform,
        base::screenconfig,
        ssh::client,
        ssh::server,
        role::salt::minions,
        role::trebuchet,
        nrpe


    # include base::monitor::host.
    # if $nagios_contact_group is set, then use it
    # as the monitor host's contact group.
    class { 'base::monitoring::host':
        contact_group => $::nagios_contact_group ? {
            undef   => 'admins',
            default => $::nagios_contact_group,
        }
    }

    # CA for the new ldap-eqiad/ldap-codfw ldap servers, among
    # other things.
    include certificates::globalsign_ca
    # TODO: Kill the old wmf_ca
    include certificates::wmf_ca
    include certificates::wmf_ca_2014_2017
}
