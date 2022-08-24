class profile::base::labs(
    Wmflib::Ensure $unattended_wmf = lookup('profile::base::labs::unattended_wmf'),
    Wmflib::Ensure $unattended_distro = lookup('profile::base::labs::unattended_distro'),
    Boolean $send_puppet_failure_emails = lookup('send_puppet_failure_emails', {'default_value' => true}),
    Boolean $cleanup_puppet_client_bucket = lookup('profile::base::labs::cleanup_puppet_client_bucket', {'default_value' => false}),
    Integer $client_bucket_file_age = lookup('profile::base::labs::client_bucket_file_age', {'default_value' => 14}),
){

    # profile base is shared with production
    include profile::base
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

    # Turn on idmapd by default
    file { '/etc/default/nfs-common':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/base/labs/nfs-common.default',
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

    systemd::timer::job { 'send_puppet_failure_emails':
        ensure          => $ensure_puppet_emails,
        description     => 'Send emails about Puppet failures',
        command         => '/usr/local/sbin/puppet_alert.py',
        interval        => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* 08:15:00',
        },
        logging_enabled => false,
        user            => 'root',
        require         => File['/usr/local/sbin/puppet_alert.py'],
    }

    # clean up puppet client bucket (T165885)
    systemd::timer::job { 'cleanup_puppet_client_bucket':
        ensure             => $cleanup_puppet_client_bucket.bool2str('present','absent'),
        description        => 'Delete old files from the puppet client bucket',
        command            => "/usr/bin/find /var/lib/puppet/clientbucket/ -type f -mtime +${client_bucket_file_age} -atime +${client_bucket_file_age} -delete",
        interval           => {
            'start'    => 'OnUnitInactiveSec',
            'interval' => '24h',
        },
        logging_enabled    => false,
        monitoring_enabled => false,
        user               => 'root',
    }
}
