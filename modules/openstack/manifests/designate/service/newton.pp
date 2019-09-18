class openstack::designate::service::newton
{
    # this class seems simple enough to don't require per-debian release split
    # now, will revisit later
    require "openstack::serverpackages::newton::${::lsbdistcodename}"

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
}
