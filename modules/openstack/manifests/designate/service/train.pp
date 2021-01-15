class openstack::designate::service::train
{
    # this class seems simple enough to don't require per-debian release split
    # now, will revisit later
    require "openstack::serverpackages::train::${::lsbdistcodename}"

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

    # Hack to fix domain deletion
    # Upstream bug: https://bugs.launchpad.net/designate/+bug/1880230
    # This will need to be forwarded to S and T, at least
    file { '/usr/lib/python3/dist-packages/designate/backend/impl_pdns4.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/openstack/train/designate/hacks/impl_pdns4.py';
    }
}
