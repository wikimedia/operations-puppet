class openstack::designate::service::mitaka
{
    # this class seems simple enough to don't require per-debian release split
    # now, will revisit later
    require "openstack::serverpackages::mitaka::${::lsbdistcodename}"

    $packages = [
        'designate-sink',
        'designate-common',
        'designate',
        'designate-api',
        'designate-doc',
        'designate-central',
    ]

    package { $packages:
        ensure => 'present',
    }

    # there is a bunch of config files that are mitaka-specific that needs to
    # be reallocated here from openstack::designate::service. Will revisit
    # later
}
