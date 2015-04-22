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
#
# Sample Usage:
#
class toollabs::mailrelay inherits toollabs
{
    include gridengine::submit_host,
            toollabs::infrastructure

    class { 'exim4':
        queuerunner => 'combined',
        config      => template('toollabs/exim4.conf.erb'),
        variant     => 'heavy',
        require     => File['/usr/local/sbin/localuser',
                            '/usr/local/sbin/maintainers'],
    }

    file { "${toollabs::store}/mail-relay":
        ensure  => absent,
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
