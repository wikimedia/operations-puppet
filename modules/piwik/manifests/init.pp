# == Class: piwik
#
# Piwik is an open-source analytics platform.
#
# https://piwik.org/
#
# Piwik's installation is meant to be executed manually using its UI,
# to initialize the database and generate the related config file.
# Therefore each new deployment from scratch will require some manual work,
# please keep it mind.
#
# Misc:
# Q: Where did the deb package come from?
# A: http://debian.piwik.org, imported to jessie-wikimedia.
#
class piwik (
    $database_host     = 'localhost',
    $database_username = 'piwik',
    $trusted_hosts     = [],
    $piwik_username    = 'www-data',
) {
    require_package('piwik')

    $database_name = 'piwik'
    $database_table_prefix = 'piwik_'
    $proxy_client_headers = ['HTTP_X_FORWARDED_FOR']

    file { '/etc/piwik/config.ini.php':
        ensure  => present,
        content => template('piwik/config.ini.php.erb'),
        owner   => $piwik_username,
        group   => $piwik_username,
        mode    => '0750',
        require => Package['piwik'],
    }
}