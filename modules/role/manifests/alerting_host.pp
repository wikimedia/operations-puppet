# = Class: role::alerting_host
#
# Sets up a full production alerting host, including
# an icinga instance, tcpircbot, and certspotter
#
# = Parameters
#
class role::alerting_host {
    include profile::base::production
    include profile::firewall

    include profile::icinga
    include profile::icinga::performance
    include profile::icinga::logmsgbot
    include profile::certspotter
    include profile::scap::dsh

    include profile::dns::auth::monitoring::global
    include profile::statograph

    include profile::alertmanager
    include profile::alertmanager::irc
    include profile::alertmanager::web
    include profile::alertmanager::ack
    include profile::alertmanager::api
    include profile::alertmanager::phab
    include profile::alertmanager::triage
    include profile::conftool::hiddenparma
    include profile::klaxon
    include profile::vopsbot

    include profile::corto

    class { 'httpd::mpm':
        mpm => 'prefork'
    }

    class { 'httpd':
        modules => ['headers', 'rewrite', 'authnz_ldap', 'authn_file', 'cgi',
                    'ssl', 'proxy_http', 'allowmethods'],
    }
}
