class openstack::nova::common::rocky::buster(
) {
    require ::openstack::serverpackages::rocky::buster

    $packages = [
        'unzip',
        'bridge-utils',
        'python-mysqldb',
        'nova-common',
    ]

    package { $packages:
        ensure => 'present',
    }

    # Overlay a tooz driver that has an encoding bug.  This bug is present
    #  in version of this package found in the rocky apt repo, 1.62.0-1~bpo9+1.
    #  It is likely fixed in any future version, so this should probably not be
    #  forwarded to S.
    #
    # Upstream bug: https://bugs.launchpad.net/python-tooz/+bug/1530888
    file { '/usr/lib/python3/dist-packages/tooz/drivers/memcached.py':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['nova-common'],
        source  => 'puppet:///modules/openstack/rocky/toozpatch/tooz-memcached.py';
    }

    # We need to manage this file in Rocky because it was previously managed
    #  for the wmfmiddleware injection hack.  In the future we can just
    #  leave whatever file gets installed by the nova package in place.
    file { '/etc/nova/api-paste.ini':
            content => template('openstack/rocky/nova/common/api-paste.ini.erb'),
            owner   => 'nova',
            group   => 'nogroup',
            mode    => '0440',
            require => Package['nova-common'];
    }
}
