# = Class: role::alerting_host
#
# Sets up a full production alerting host, including
# an icinga instance, tcpircbot, and certspotter
#
# = Parameters
#
class role::alerting_host {

    system::role{ 'alerting_host':
        description => 'central host for health checking and alerting'
    }

    include profile::base::production
    include profile::base::firewall

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
    include profile::klaxon
    include profile::vopsbot

    # WMF services that require monitoring but do not have their
    # own standalone alerting server.
    include profile::wikifunctions::beta

    class { 'httpd::mpm':
        mpm => 'prefork'
    }

    class { 'httpd':
        modules => ['headers', 'rewrite', 'authnz_ldap', 'authn_file', 'cgi',
                    'ssl', 'proxy_http', 'allowmethods'],
    }
}
