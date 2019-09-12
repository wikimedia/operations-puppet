# == Class: role::piwik
#
class role::piwik {

    system::role { 'piwik':
        description => 'Analytics Piwik/Matomo server',
    }

    include ::profile::standard
    include ::profile::base::firewall

    include ::profile::piwik::webserver
    include ::profile::tlsproxy::service
    include ::profile::piwik::instance
    # override profile::backup::enable to disable regular backups
    include ::profile::analytics::backup::database
    include ::profile::piwik::database

}
