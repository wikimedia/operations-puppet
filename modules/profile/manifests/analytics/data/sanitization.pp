# == Class profile::analytics::data::sanitization
#
# This profile deploys all the data sanitization
# facilities needed by the Analytics team to apply
# the data retention guidelines.
#
class profile::analytics::data::sanitization {

    $sanitization_config_dir = '/etc/analytics/sanitization'
    $eventlogging_whitelist_path = "${sanitization_config_dir}/whitelist.yaml"

    file { '/etc/analytics':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { $sanitization_config_dir:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { $eventlogging_whitelist_path:
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/profile/analytics/data/sanitization/eventlogging_purging_whitelist.yaml',
    }

}