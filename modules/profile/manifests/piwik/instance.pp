# == Class: profile::piwik::instance
#
# Configuration options for piwik.wikimedia.org
#
class profile::piwik::instance (
    $database_password = hiera('profile::piwik::database_password'),
    $admin_username    = hiera('profile::piwik::admin_username'),
    $admin_password    = hiera('profile::piwik::admin_password'),
    $password_salt     = hiera('profile::piwik::password_salt'),
    $trusted_hosts = ['piwik.wikimedia.org', 'wikimediafoundation.org'],
) {
    class { 'piwik':
        database_password => $database_password,
        admin_username    => $admin_username,
        admin_password    => $admin_password,
        password_salt     => $password_salt,
    }
}