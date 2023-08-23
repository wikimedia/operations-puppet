# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::l3_agent::antelope(
    $report_interval,
) {
    class { "openstack::neutron::l3_agent::antelope::${::lsbdistcodename}": }

    file { '/etc/neutron/l3_agent.ini':
            owner   => 'neutron',
            group   => 'neutron',
            mode    => '0640',
            content => template('openstack/antelope/neutron/l3_agent.ini.erb'),
            require => Package['neutron-l3-agent'];
    }

    # neutron-l3-agent Depends radvd on stein, but we don't use and don't
    # configure it. To prevent icinga from reporting a unit in bad shape, just
    # disable it.
    systemd::mask { 'radvd.service':
        before => Package['neutron-l3-agent'],
    }

    # hope we only need this for antelope, and next version includes the fix
    $file_to_patch = '/usr/lib/python3/dist-packages/neutron/agent/l3/keepalived_state_change.py'
    $patch_file = "${file_to_patch}.patch"
    file { $patch_file:
        source => 'puppet:///modules/openstack/antelope/neutron/hacks/keepalived_state_change.py.patch',
        mode   => '0644',
    }
    exec { "apply ${patch_file}":
        command => "/usr/bin/patch --forward ${file_to_patch} ${patch_file}",
        unless  => "/usr/bin/patch --reverse --dry-run -f ${file_to_patch} ${patch_file}",
        require => [File[$patch_file], Package['neutron-l3-agent']],
    }
}
