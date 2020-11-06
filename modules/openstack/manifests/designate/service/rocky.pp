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

    # Hack to fix domain deletion
    # Upstream bug: https://bugs.launchpad.net/designate/+bug/1880230
    # This will need to be forwarded to S and T, at least
    file { '/usr/lib/python3/dist-packages/designate/backend/impl_pdns4.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/openstack/rocky/designate/hacks/impl_pdns4.py';
    }

    if debian::codename::ge('buster') {
        # Hack around drastic failure of ThreadPoolExecutor with python 3.7
        # Upstream bug: https://bugs.launchpad.net/designate/+bug/1782647
        # This is only needed on buster, and is fixed in the upstream in S
        file { '/usr/lib/python3/dist-packages/designate/worker/processing.py':
            ensure => 'present',
            owner  => 'root',
            group  => 'root',
            mode   => '0644',
            source => 'puppet:///modules/openstack/rocky/designate/hacks/processing.py';
        }
    }
}
