class profile::toolforge::mailrelay (
    String  $external_hostname = lookup('profile::toolforge::mailrelay::external_hostname', {'default_value' => 'mail.tools.wmflabs.org'}),
    String  $mail_domain       = lookup('profile::toolforge::mail_domain',                  {'default_value' => 'tools.wmflabs.org'}),
    String  $cert_name         = lookup('profile::toolforge::cert_name',                    {'default_value' => 'tools_mail'}),
    Boolean $tls               = lookup('profile::toolforge::mailrelay::enable_tls',        {'default_value' => true}),
) {
    class { '::exim4':
        queuerunner => 'combined',
        config      => template('profile/toolforge/mail-relay.exim4.conf.erb'),
        variant     => 'heavy',
        require     => File['/usr/local/sbin/localuser',
                            '/usr/local/sbin/maintainers'],
    }

    # Manually maintained outbound sender blocklist
    file { '/etc/exim4/deny_senders.list':
        ensure  => present,
        owner   => 'root',
        group   => 'Debian-exim',
        mode    => '0440',
        replace => false,
        content => '# Add MAIL FROM address to block. One per line',
        require => Package['exim4-config'],
        notify  => Service['exim4'],
    }

    file { '/etc/exim4/ratelimits':
        ensure  => directory,
        owner   => 'root',
        group   => 'Debian-exim',
        mode    => '0550',
        require => Package['exim4-config'],
    }

    file { '/etc/exim4/ratelimits/sender_hourly_limits':
        ensure  => present,
        owner   => 'root',
        group   => 'Debian-exim',
        mode    => '0440',
        require => File['/etc/exim4/ratelimits'],
        source  => 'puppet:///modules/profile/toolforge/mailrelay/sender_hourly_limits',
    }

    file { '/etc/exim4/ratelimits/host_hourly_limits':
        ensure  => present,
        owner   => 'root',
        group   => 'Debian-exim',
        mode    => '0440',
        require => File['/etc/exim4/ratelimits'],
        source  => 'puppet:///modules/profile/toolforge/mailrelay/host_hourly_limits',
    }

    file { '/usr/local/sbin/localuser':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/toolforge/mailrelay/localuser',
    }

    file { '/usr/local/sbin/maintainers':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/toolforge/mailrelay/maintainers',
    }

    file { '/etc/aliases':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/profile/toolforge/mailrelay/aliases',
    }

    if $tls {
        letsencrypt::cert::integrated { $cert_name:
            subjects   => $external_hostname,
            key_group  => 'Debian-exim',
            puppet_svc => 'nginx',
            system_svc => 'nginx',
        }

        class { 'nginx':
            variant => 'light',
        }

        nginx::site { 'letsencrypt-standalone':
            content => template('letsencrypt/cert/integrated/standalone.nginx.erb'),
        }

        ferm::service { 'nginx-http':
            proto => 'tcp',
            port  => '80',
        }
    }

    diamond::collector::extendedexim { 'extended_exim_collector': }
}
