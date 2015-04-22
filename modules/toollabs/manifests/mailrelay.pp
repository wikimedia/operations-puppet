# Class: toollabs::mailrelay
#
# This role sets up a mail relay in the Tool Labs model.
#
# Parameters:
#
# Actions:
#
# Requires:
#  - Hiera: toollabs::is_mail_relay: true
#  - Hiera: toollabs::external_hostname set
#
# Sample Usage:
#
class toollabs::mailrelay inherits toollabs
{
    include gridengine::submit_host,
            toollabs::infrastructure

    # Hiera sanity checks

    if !$is_mail_relay {
        fail('Mail relay hosts must have toollabs::is_mail_relay set in Hiera')
    }

    if $external_hostname == undef {
        fail('Mail relay hosts must have an toollabs::external_hostname defined in Hiera')
    }

    class { 'exim4':
        queuerunner => 'combined',
        config      => template('toollabs/mail-relay.exim4.conf.erb'),
        variant     => 'heavy',
        require     => File['/usr/local/sbin/localuser',
                            '/usr/local/sbin/maintainers'],
    }

    file { '/usr/local/sbin/localuser':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/toollabs/localuser',
    }

    file { '/usr/local/sbin/maintainers':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/toollabs/maintainers',
    }

    diamond::collector::extendedexim { 'extended_exim_collector': }
}
