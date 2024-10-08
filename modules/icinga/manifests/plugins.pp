# = Class: icinga::plugins
#
# Sets up icinga check_plugins and notification commands
class icinga::plugins(
    String $icinga_user,
    String $icinga_group,
){

    ensure_packages([
        'nagios-nrpe-plugin',
        'python3-requests',
        'python3-rfc3986',
        'python3-bs4',  # for check_legal_html.py
    ])

    file { '/usr/lib/nagios':
        ensure => directory,
        owner  => $icinga_user,
        group  => $icinga_group,
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins':
        ensure => directory,
        owner  => $icinga_user,
        group  => $icinga_group,
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/eventhandlers':
        ensure => directory,
        owner  => $icinga_user,
        group  => $icinga_group,
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/eventhandlers/submit_check_result':
        source => 'puppet:///modules/icinga/submit_check_result.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/var/lib/nagios/rm':
        ensure => directory,
        owner  => $icinga_user,
        group  => 'nagios',
        mode   => '0775',
    }
    file { '/etc/nagios-plugins':
        ensure => directory,
        owner  => $icinga_user,
        group  => $icinga_group,
        mode   => '0755',
    }
    # TODO: Purge this directoy instead of populating it is probably not very
    # future safe. We should be populating it instead
    file { '/etc/nagios-plugins/config':
        ensure  => directory,
        purge   => true,
        recurse => true,
        owner   => $icinga_user,
        group   => $icinga_group,
        mode    => '0755',
        notify  => Service['icinga'],
    }

    # WMF custom service checks
    file { '/usr/lib/nagios/plugins/check_ripe_atlas.py':
        ensure => absent,
    }
    file { '/usr/lib/nagios/plugins/check_librenms.py':
        source => 'puppet:///modules/icinga/check_librenms.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    $librenms_api_key_path = '/etc/icinga/librenms_api_key'
    file { $librenms_api_key_path:
        content => secret('icinga/librenms_api_key'),
        owner   => $icinga_user,
        group   => $icinga_group,
        mode    => '0440',
    }
    file { '/usr/lib/nagios/plugins/check_legal_html.py':
        source => 'puppet:///modules/icinga/check_legal_html.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_wikitech_static':
        source => 'puppet:///modules/icinga/check_wikitech_static.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_wikitech_static_version':
        source => 'puppet:///modules/icinga/check_wikitech_static_version.py',
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
    file { '/usr/lib/nagios/plugins/check_MySQL.php':
        source => 'puppet:///modules/icinga/check_MySQL.php',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    class { '::nagios_common::commands':
        owner  => $icinga_user,
        group  => $icinga_group,
        notify => Service['icinga'],
    }

    include ::passwords::nagios::mysql

    $nagios_mysql_check_pass = $passwords::nagios::mysql::mysql_check_pass

    nagios_common::check_command::config { 'smtp.cfg':
        ensure     => present,
        content    => template('icinga/check_commands/smtp.cfg.erb'),
        config_dir => '/etc/icinga',
        owner      => $icinga_user,
        group      => $icinga_group,
    }

    nagios_common::check_command::config { 'mysql.cfg':
        ensure     => present,
        content    => template('icinga/check_commands/mysql.cfg.erb'),
        config_dir => '/etc/icinga',
        owner      => $icinga_user,
        group      => $icinga_group,
    }

    nagios_common::check_command::config { 'check_ripe_atlas.cfg':
        ensure     => absent,
        config_dir => '/etc/icinga',
    }

    nagios_common::check_command::config { 'check_librenms.cfg':
        ensure     => present,
        content    => template('icinga/check_commands/check_librenms.cfg.erb'),
        config_dir => '/etc/icinga',
        owner      => $icinga_user,
        group      => $icinga_group,
    }

    nagios_common::check_command::config { 'check_legal_html.cfg':
        ensure     => present,
        content    => template('icinga/check_commands/check_legal_html.cfg.erb'),
        config_dir => '/etc/icinga',
        owner      => $icinga_user,
        group      => $icinga_group,
    }

    nagios_common::check_command::config { 'check_wikitech_static.cfg':
        ensure     => present,
        content    => template('icinga/check_commands/check_wikitech_static.cfg.erb'),
        config_dir => '/etc/icinga',
        owner      => $icinga_user,
        group      => $icinga_group,
    }

    nagios_common::check_command::config { 'check_wikitech_static_version.cfg':
        ensure     => present,
        content    => template('icinga/check_commands/check_wikitech_static_version.cfg.erb'),
        config_dir => '/etc/icinga',
        owner      => $icinga_user,
        group      => $icinga_group,
    }

    # Include elasticsearch checks
    include ::icinga::elasticsearch::base_plugin
    include ::icinga::elasticsearch::cirrus_plugin
}
