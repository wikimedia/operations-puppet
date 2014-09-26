#= Class: icinga::config
#
# Sets up configuration required for the icinga
# instance. Sets up custom check commands as well
class icinga::config {
    include passwords::nagios::mysql

    $nagios_mysql_check_pass = $passwords::nagios::mysql::mysql_check_pass

    file { '/etc/icinga/cgi.cfg':
        source => 'puppet:///modules/icinga/cgi.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file { '/etc/icinga/icinga.cfg':
        source => 'puppet:///modules/icinga/icinga.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file { '/etc/icinga/nsca_frack.cfg':
        source => 'puppet:///private/nagios/nsca_frack.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file { '/etc/icinga/checkcommands.cfg':
        content => template('icinga/checkcommands.cfg.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

    file { '/etc/icinga/contactgroups.cfg':
        source => 'puppet:///modules/icinga/contactgroups.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    class { 'nagios_common::contacts':
        source => 'puppet:///private/nagios/contacts.cfg',
    }

    class { [
      'nagios_common::user_macros',
      'nagios_common::timeperiods',
      'nagios_common::notification_commands',
    ] :
    }
}
