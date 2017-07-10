# == Class: role::piwik::server
#
class role::piwik::server {
    include ::standard
    include ::profile::piwik::webserver
    include ::profile::piwik::instance
    # override profile::backup::enable to disable regular backups
    include ::profile::piwik::backup

    # TODO - puppetization of mysql instance
    require_package('mysql-server')

    system::role { 'piwik::server':
        description => 'Analytics piwik server',
    }
}
