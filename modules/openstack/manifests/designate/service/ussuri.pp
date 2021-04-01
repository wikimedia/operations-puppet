class openstack::designate::service::ussuri
{
    # this class seems simple enough to don't require per-debian release split
    # now, will revisit later
    require "openstack::serverpackages::ussuri::${::lsbdistcodename}"

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
    # This may be fixed upstream in V
    file { '/usr/lib/python3/dist-packages/designate/backend/impl_pdns4.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/openstack/ussuri/designate/hacks/impl_pdns4.py';
    }
}
