# == Class: role::piwik
#
class role::piwik {

    system::role { 'piwik':
        description => 'Analytics Piwik/Matomo server',
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::base::firewall::log

    include ::profile::piwik::webserver

    include ::profile::piwik::instance
    # override profile::backup::enable to disable regular backups
    include ::profile::piwik::backup
    include ::profile::piwik::database

}
