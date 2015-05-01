# = Class: icinga::plugins
#
# Sets up icinga check_plugins and notification commands
class icinga::plugins {
    file { '/usr/lib/nagios':
        ensure => directory,
        owner  => 'icinga',
        group  => 'icinga',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins':
        ensure => directory,
        owner  => 'icinga',
        group  => 'icinga',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/eventhandlers':
        ensure => directory,
        owner  => 'icinga',
        group  => 'icinga',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/eventhandlers/submit_check_result':
        source => 'puppet:///modules/icinga/submit_check_result',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/var/lib/nagios/rm':
        ensure => directory,
        owner  => 'icinga',
        group  => 'nagios',
        mode   => '0775',
    }
    file { '/etc/nagios-plugins':
        ensure => directory,
        owner  => 'icinga',
        group  => 'icinga',
        mode   => '0755',
    }
    file { '/etc/nagios-plugins/config':
        ensure => directory,
        owner  => 'icinga',
        group  => 'icinga',
        mode   => '0755',
    }

    File <| tag == nagiosplugin |>

    # WMF custom service checks
    file { '/usr/lib/nagios/plugins/check_ripe_atlas.py':
        source => 'puppet:///modules/icinga/check_ripe_atlas.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_mysql-replication.pl':
        source => 'puppet:///modules/icinga/check_mysql-replication.pl',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_longqueries':
        source => 'puppet:///modules/icinga/check_longqueries',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_MySQL.php':
        source => 'puppet:///modules/icinga/check_MySQL.php',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_nrpe':
        source => 'puppet:///modules/icinga/check_nrpe',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_ram.sh':
        source => 'puppet:///modules/icinga/check_ram.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    class { [
        'nagios_common::commands',
        'nagios_common::check::ganglia'
    ] :
    }

    include passwords::nagios::mysql

    $nagios_mysql_check_pass = $passwords::nagios::mysql::mysql_check_pass

    nagios_common::check_command::config { 'smtp.cfg':
        ensure     => present,
        content    => template('icinga/check_commands/smtp.cfg.erb'),
        config_dir => '/etc/icinga',
        owner      => 'icinga',
        group      => 'icinga'
    }

    nagios_common::check_command::config { 'mysql.cfg':
        ensure     => present,
        content    => template('icinga/check_commands/mysql.cfg.erb'),
        config_dir => '/etc/icinga',
        owner      => 'icinga',
        group      => 'icinga'
    }

    # Include check_elasticsearch from elasticsearch module
    include elasticsearch::nagios::plugin

    # some default configuration files conflict and should be removed
    file { '/etc/nagios-plugins/config/mailq.cfg':
        ensure => absent,
    }
}
