# This role sets up a mail relay in the Tool Labs model.
# Requires:
#  - Hiera: toollabs::is_mail_relay: true
#  - Hiera: toollabs::external_hostname set

class toollabs::mailrelay inherits toollabs
{

    if !$toollabs::is_mail_relay {
        fail('Mail relay hosts must have toollabs::is_mail_relay set in Hiera')
    }

    if $toollabs::external_hostname == undef {
        fail('Mail relay hosts must have an toollabs::external_hostname defined in Hiera')
    }

    include ::gridengine::submit_host
    include ::toollabs::infrastructure

    class { '::exim4':
        queuerunner => 'combined',
        config      => template('toollabs/mail-relay.exim4.conf.erb'),
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
        source => 'puppet:///modules/toollabs/localuser',
    }

    file { '/usr/local/sbin/maintainers':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/maintainers',
    }

    file { '/etc/aliases':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/toollabs/aliases',
    }

    diamond::collector::extendedexim { 'extended_exim_collector': }
}
