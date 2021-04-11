# Access credentials for the keystone 'novaobserver' account
class profile::openstack::base::observerenv(
    String       $region            = lookup('profile::openstack::base::region'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    String       $os_user           = lookup('profile::openstack::base::observer_user'),
    String       $os_password       = lookup('profile::openstack::base::observer_password'),
    String       $os_project        = lookup('profile::openstack::base::observer_project'),
  ) {

    openstack::util::envscript { 'novaobserver':
        region                 => $region,
        keystone_api_fqdn      => $keystone_api_fqdn,
        keystone_api_port      => 5000,
        keystone_api_interface => 'public',
        os_user                => $os_user,
        os_password            => $os_password,
        os_project             => $os_project,
        scriptpath             => '/usr/local/bin/observerenv.sh',
        yaml_mode              => '0444',
    }
}
