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

    include ::ldap::role::config::labs
    $ldapconfig = $ldap::role::config::labs::ldapconfig

    class { '::exim4':
        queuerunner => 'combined',
        config      => template('toollabs/mail-relay.exim4.conf.erb'),
        variant     => 'heavy',
    }

    # TODO: Remove after deployment.
    file { '/usr/local/sbin/localuser':
        ensure  => absent,
        require => Class['exim4'],
    }

    # TODO: Remove after deployment.
    file { '/usr/local/sbin/maintainers':
        ensure  => absent,
        require => Class['exim4'],
    }

    diamond::collector::extendedexim { 'extended_exim_collector': }
}
