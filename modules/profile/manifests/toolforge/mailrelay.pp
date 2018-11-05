class profile::toolforge::mailrelay(
    $external_hostname = hiera('profile::toolforge::mailrelay::external_hostname'),
    $mail_domain = hiera('profile::toolforge::mail_domain', 'tools.wmflabs.org'),
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

    diamond::collector::extendedexim { 'extended_exim_collector': }
}
