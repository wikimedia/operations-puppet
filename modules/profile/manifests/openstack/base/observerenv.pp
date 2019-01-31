# Access credentials for the keystone 'novaobserver' account
class profile::openstack::base::observerenv(
    $region = hiera('profile::openstack::base::region'),
    $keystone_host = hiera('profile::openstack::base::keystone_host'),
    $observer_user = hiera('profile::openstack::base::observer_user'),
    $observer_password = hiera('profile::openstack::base::observer_password'),
  ) {

    # Keystone credentials for novaobserver
    file { '/etc/novaobserver.yaml':
        content => template('profile/openstack/base/novaobserver/novaobserver.yaml.erb'),
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
    }

    file { '/usr/local/bin/observerenv.sh':
        source => 'puppet:///modules/profile/openstack/base/novaobserver/observerenv.sh',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }
}
