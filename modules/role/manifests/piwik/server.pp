# == Class: role::piwik::server
#
class role::piwik::server {
    include ::profile::piwik::webserver
    include ::profile::piwik::instance

    # TODO - puppetization of mysql instance
    # Ref: T159136
    require_package('mysql-server')

    system::role { 'role::piwik::server':
        description => 'Analytics piwik server',
    }
}
