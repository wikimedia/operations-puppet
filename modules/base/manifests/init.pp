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
    }

    $puppetmaster = hiera('puppetmaster')

    class { 'base::puppet':
        server   => $puppetmaster,
    }

    include passwords::root
    include base::grub
    include base::resolving
    include ::rsyslog
    include base::remote_syslog
    include base::sysctl
    include ::motd
    include base::standard-packages
    include base::environment
    include base::phaste
    include base::screenconfig
    include base::certificates
    include ssh::client
    include ssh::server
    include role::salt::minions
    include role::trebuchet
    include nrpe
    include base::kernel

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
}
