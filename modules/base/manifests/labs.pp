class base::labs inherits base {
    include apt::unattendedupgrades,
        apt::noupgrade

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

    file { '/usr/local/sbin/notify_maintainers.py':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/base/labs/notify_maintainers.py',
        before => File['/usr/local/sbin/puppet_alert.py'],
    }

    file { '/usr/local/sbin/puppet_alert.py':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/base/labs/puppet_alert.py',
    }

    if hiera('send_puppet_failure_emails', false) {
        cron { 'send_puppet_failure_emails':
            ensure  => present,
            command => '/usr/local/sbin/puppet_alert.py',
            hour    => 8,
            minute  => '15',
            user    => 'root',
        }
    }

    # Set a root password only if we're still governed by the official Labs
    #  puppetmaster.  Self- and locally-hosted instances are on their own,
    #  but most likely already registered a password during their initial
    #  setup.
    if $::puppetmastername == hiera('labs_puppet_master') {
        # Create a root password and store it on the puppetmaster
        user { 'root':
            password => regsubst(
                generate('/usr/local/sbin/make-labs-root-password', $::labsproject),
                '\s$', '')
        }
    }
}
