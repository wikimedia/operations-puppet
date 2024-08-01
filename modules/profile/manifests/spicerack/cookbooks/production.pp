# SPDX-License-Identifier: Apache-2.0
class profile::spicerack::cookbooks::production {
    $firmware_store_dir = '/srv/firmware'
    require passwords::misc::scripts  # For the databases replication credentials

    wmflib::dir::mkdir_p($firmware_store_dir, {
        group => 'datacenter-ops',
        mode  => '2775',
    })

    file { '/etc/spicerack/cookbooks/sre.hardware.upgrade-firmware.yaml':
        ensure  => file,
        content => {
            'firmware_store' => $firmware_store_dir,
        }.to_yaml,
    }

    file { '/etc/spicerack/cookbooks/sre.network.cf.yaml':
        ensure  => file,
        owner   => 'root',
        group   => 'ops',
        mode    => '0440',
        content => secret('spicerack/cookbooks/sre.network.cf.yaml'),
    }

    # Configuration file for switching services between datacenters
    # For each discovery record for active-active services, extract the
    # actual dns from monitoring if available.
    $discovery_records = wmflib::service::fetch().filter |$label, $record| {
        $record['discovery'] != undef
    }
    file { '/etc/spicerack/cookbooks/sre.switchdc.services.yaml':
        ensure  => file,
        owner   => 'root',
        group   => 'ops',
        mode    => '0440',
        content => template('profile/cookbooks/sre.switchdc.services.yaml.erb'),
    }

    file { '/etc/spicerack/cookbooks/sre.switchdc.databases.yaml':
        ensure  => file,
        owner   => 'root',
        group   => 'ops',
        mode    => '0440',
        content => {
            'repl_user' => $passwords::misc::scripts::mysql_repl_user,
            'repl_pass' => $passwords::misc::scripts::mysql_repl_pass,
        }.to_yaml,
    }

}
