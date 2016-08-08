# = Class: icinga::event_handlers::raid
#
# Sets up icinga RAID event handler
class icinga::event_handlers::raid {
    include passwords::phabricator

    phabricator::bot { 'opsbot':
        token => $passwords::phabricator::opsbot_token,
        owner => 'icinga',
        group => 'icinga',
    }

    package { 'python-phabricator':
        ensure => 'present',
    }

    file { '/usr/lib/nagios/plugins/eventhandlers/raid_handler':
        source => 'puppet:///modules/icinga/raid_handler.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    nagios_common::check_command::config { 'raid_handler':
        ensure     => present,
        content    => template('icinga/event_handlers/raid_handler.cfg.erb'),
        config_dir => '/etc/icinga',
        owner      => 'icinga',
        group      => 'icinga'
    }
}
