class openstack::designate::service::rocky
{
    # this class seems simple enough to don't require per-debian release split
    # now, will revisit later
    require "openstack::serverpackages::rocky::${::lsbdistcodename}"

    $packages = [
        'designate-sink',
        'designate-common',
        'designate-mdns',
        'designate',
        'designate-api',
        'designate-doc',
        'designate-central',
        'python-git',
        'python3-git',
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
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/openstack/rocky/toozpatch/tooz-memcached.py';
    }
}
