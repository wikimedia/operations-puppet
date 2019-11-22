class openstack::designate::service::ocata
{
    # this class seems simple enough to don't require per-debian release split
    # now, will revisit later
    require "openstack::serverpackages::ocata::${::lsbdistcodename}"

    $packages = [
        'designate-sink',
        'designate-common',
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
