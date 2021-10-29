# the purpose of this profile is to basically lookup the hiera hash, the
# actual logic lives in the inner class
class profile::ceph::auth::load_all (
    Hash[String, Ceph::Auth::ClientAuth] $configuration = lookup('profile::ceph::auth::load_all::configuration'),
    # this is temporary to allow a gradual deployment
    Boolean $enabled = lookup('profile::ceph::auth::load_all::enabled'),
) {
    if ($enabled) {
        class { 'ceph::auth::load_all':
            configuration => $configuration,
        }
    }
}
