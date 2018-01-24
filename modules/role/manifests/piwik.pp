# == Class: role::piwik
#
class role::piwik {
    include ::standard
    include ::profile::base::firewall
    include ::profile::piwik::webserver
    include ::profile::piwik::instance
    # override profile::backup::enable to disable regular backups
    include ::profile::piwik::backup
    include ::profile::piwik::database

    system::role { 'piwik':
        description => 'Analytics piwik server',
    }
}
