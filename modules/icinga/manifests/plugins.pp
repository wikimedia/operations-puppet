# = Class: icinga::plugins
#
# Sets up icinga check_plugins and notification commands
class icinga::plugins(
    String $icinga_user,
    String $icinga_group,
){
    package { 'nagios-nrpe-plugin':
        ensure => present,
    }
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
    }

    File <| tag == nagiosplugin |>

    # WMF custom service checks
    file { '/usr/lib/nagios/plugins/check_ripe_atlas.py':
        source => 'puppet:///modules/icinga/check_ripe_atlas.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
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
    # Google safebrowsing lookup API client
    file { '/usr/lib/nagios/plugins/check_gsb.py':
        source => 'puppet:///modules/icinga/check_gsb.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    # for "check_lastmod" - Check if any website has recently been updated
    # Originally added to check if Planet content updates working (T203208)
    require_package('python3-requests', 'python3-rfc3986')

    # Wikidata dispatcher monitoring
    file { '/usr/lib/nagios/plugins/check_wikidata_crit':
        source => 'puppet:///modules/icinga/check_wikidata_crit',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    class { '::nagios_common::commands':
        owner => $icinga_user,
        group => $icinga_group,
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
        ensure     => present,
        content    => template('icinga/check_commands/check_ripe_atlas.cfg.erb'),
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

    nagios_common::check_command::config { 'check_wikidata_crit.cfg':
        ensure     => present,
        content    => template('icinga/check_commands/check_wikidata_crit.cfg.erb'),
        config_dir => '/etc/icinga',
        owner      => $icinga_user,
        group      => $icinga_group,
    }

    # Include check_elasticsearch from elasticsearch module
    include ::elasticsearch::nagios::plugin
}
