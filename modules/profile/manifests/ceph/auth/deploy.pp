# This profile deploys but does not load the given authorizations.
# You only need one of profile::ceph::auth::load_all or profile::ceph::auth::deploy, the first will also deploy all known auths.
class profile::ceph::auth::deploy (
    Ceph::Auth::Conf  $configuration  = lookup('profile::ceph::auth::deploy::configuration'),
    Array[String[1]]  $selected_creds = lookup('profile::ceph::auth::deploy::selected_creds'),
    # this is temporary to allow a gradual deployment
    Boolean           $enabled        = lookup('profile::ceph::auth::deploy::enabled'),
) {
    if ($enabled) {
        class { 'ceph::auth::deploy':
            configuration  => $configuration,
            selected_creds => $selected_creds,
        }
    }
}
