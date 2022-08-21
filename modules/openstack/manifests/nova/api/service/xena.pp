# SPDX-License-Identifier: Apache-2.0

class openstack::nova::api::service::xena(
    Stdlib::Port $api_bind_port,
    Stdlib::Port $metadata_bind_port,
    Integer $compute_workers,
) {
    # simple enough to don't require per-debian release split
    require "openstack::serverpackages::xena::${::lsbdistcodename}"

    ensure_packages(['nova-api', 'patch'])

    file { '/etc/init.d/nova-api':
        content => template('openstack/xena/nova/api/nova-api'),
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        notify  => Service['nova-api'],
        require => Package['nova-api'];
    }

    # Hack in regex validation for instance names.
    #  Context can be found in T207538
    $file_to_patch = '/usr/lib/python3/dist-packages/nova/api/openstack/compute/servers.py'
    $patch_file = "${file_to_patch}.patch"
    file {$patch_file:
        source => 'puppet:///modules/openstack/xena/nova/hacks/servers.py.patch',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    exec { "apply ${patch_file}":
        command => "/usr/bin/patch --forward ${file_to_patch} ${patch_file}",
        unless  => "/usr/bin/patch --reverse --dry-run -f ${file_to_patch} ${patch_file}",
        require => [File[$patch_file], Package['nova-api']],
        notify  => Service['nova-api'],
    }

    file { '/etc/init.d/nova-api-metadata':
        content => template('openstack/xena/nova/api/nova-api-metadata'),
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        notify  => Service['nova-api-metadata'],
        require => Package['nova-api'];
    }
    file { '/etc/nova/nova-api-metadata-uwsgi.ini':
        content => template('openstack/xena/nova/api/nova-api-metadata-uwsgi.ini.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        notify  => Service['nova-api-metadata'],
        require => Package['nova-api'];
    }
    service { 'nova-api-metadata':
        ensure    => 'running',
        subscribe => [
                      File['/etc/nova/nova.conf'],
                      File['/etc/nova/policy.yaml'],
            ],
        require   => Package['nova-api'];
    }
    file { '/etc/nova/nova-api-uwsgi.ini':
        content => template('openstack/xena/nova/api/nova-api-uwsgi.ini.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        notify  => Service['nova-api-metadata'],
        require => Package['nova-api'];
    }
}
