class openstack::designate::service::pike
{
    # this class seems simple enough to don't require per-debian release split
    # now, will revisit later
    require "openstack::serverpackages::pike::${::lsbdistcodename}"

    $packages = [
        'designate-sink',
        'designate-common',
        'designate-mdns',
        'designate',
        'designate-api',
        'designate-doc',
        'designate-central',
        'python-git',
    ]

    package { $packages:
        ensure => 'present',
    }
}
