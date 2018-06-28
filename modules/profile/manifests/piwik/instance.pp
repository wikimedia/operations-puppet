# == Class: profile::piwik::instance
#
# Configuration options for piwik.wikimedia.org
#
class profile::piwik::instance (
    $database_password = hiera('profile::piwik::database_password'),
    $admin_username    = hiera('profile::piwik::admin_username'),
    $admin_password    = hiera('profile::piwik::admin_password'),
    $password_salt     = hiera('profile::piwik::password_salt'),
    $trusted_hosts     = hiera('profile::piwik::trusted_hosts',
        ['piwik.wikimedia.org', 'wikimediafoundation.org']),
) {
    # Piwik has been rebranded to Matomo, but the core stays the same.
    # We are going to keep profile/roles with the Piwik naming for a bit
    # more since it is harmless.
    class { 'matomo':
        database_password  => $database_password,
        admin_username     => $admin_username,
        admin_password     => $admin_password,
        password_salt      => $password_salt,
        trusted_hosts      => $trusted_hosts,
        archive_cron_url   => 'piwik.wikimedia.org',
        archive_cron_email => 'analytics-alerts@wikimedia.org',
    }
}