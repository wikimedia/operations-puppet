# Format and mount an unattched cinder volume
#
# filtertags: labs-common
class profile::labs::cindermount::srv {
    cinderutils::ensure { 'cinder_on_srv':
        mount_point => '/srv',
        min_gb      => 3,
    }
}
