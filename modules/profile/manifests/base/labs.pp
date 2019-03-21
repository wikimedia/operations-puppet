class profile::base::labs(
    $unattended_wmf = hiera('profile::base::labs::unattended_wmf'),
    $unattended_distro = hiera('profile::base::labs::unattended_distro'),
    $send_puppet_failure_emails = hiera('send_puppet_failure_emails', true),
    ) {

    include ::apt::noupgrade
    class {'::apt::unattendedupgrades':
        unattended_wmf    => $unattended_wmf,
        unattended_distro => $unattended_distro,
    }

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

    $ensure_puppet_emails = $send_puppet_failure_emails ? {
        true    => 'present',
        default => 'absent',
    }

    if os_version('debian >= jessie') {

        # TODO: Remove after change is applied
        cron { 'send_puppet_failure_emails':
            ensure => absent,
            user   => 'root',
        }

        systemd::timer::job { 'send_puppet_failure_emails':
            ensure             => $ensure_puppet_emails,
            description        => 'Send emails about Puppet failures',
            command            => '/usr/local/sbin/puppet_alert.py',
            interval           => {
                'start'    => 'OnCalendar',
                'interval' => '*-*-* *:08:15',
            },
            logging_enabled    => false,
            monitoring_enabled => false,
            user               => 'root',
            require            => File['/usr/local/sbin/puppet_alert.py'],
        }

    } else {

        # TODO: Remove once Trusty is deprecated
        cron { 'send_puppet_failure_emails':
            ensure  => $ensure_puppet_emails,
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
    #
    # Compare IPs rather than hostnames since we use an alias for the
    #  actual labs_puppet_master variable.  We only store passwords
    #  on the frontend puppetmaster, not on the workers.
    #
    #  (this is disabled pending some security work)
    #
    #if $::servername == 'labs-puppetmaster.wikimedia.org' {
    #    # Create a root password and store it on the puppetmaster
    #    user { 'root':
    #        password => regsubst(
    #            generate('/usr/local/sbin/make-labs-root-password', $::labsproject),
    #            '\s$', ''),
    #    }
    #}
}
