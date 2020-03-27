# Class: profile::ceph::common
#
# This class is used by both real ceph clients and hosts that do not use ceph
# but have the ceph-common package installed to satisfy dependencies.
#
class profile::ceph::common(
    Stdlib::Unixpath $data_dir = lookup('profile::ceph::data_dir'),
) {
    class { 'ceph::common':
        home_dir => $data_dir,
    }
}
