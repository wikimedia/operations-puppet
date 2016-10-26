# = Class: role::elasticsearch::relforge
#
# This class sets up Elasticsearch for relevance forge.
#
class role::elasticsearch::relforge {

    mount { '/srv':
        ensure  => mounted,
        fstype  => ext4,
        options => 'defaults,noatime',
        atboot  => true,
        device  => '/dev/mapper/relforge1001--vg-data',
    }

    include ::role::elasticsearch::common
    include ::elasticsearch::nagios::check

}
