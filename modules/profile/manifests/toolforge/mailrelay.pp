class profile::toolforge::mailrelay(
    String $external_hostname = hiera('profile::toolforge::mailrelay::external_hostname', 'mail.tools.wmflabs.org'),
    String $mail_domain = hiera('profile::toolforge::mail_domain', 'tools.wmflabs.org'),
    String $cert_name = hiera('profile::toolforge::cert_name', 'tools_mail'),
    String $sudo_flavor = lookup('sudo_flavor', {default_value => 'sudoldap'}),
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

    diamond::collector::extendedexim { 'extended_exim_collector':
        sudo_flavor => $sudo_flavor,
    }
}
