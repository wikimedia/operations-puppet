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

    include ::profile::standard
    include ::profile::base::firewall

    include ::profile::icinga
    include ::profile::tcpircbot
    include ::profile::certspotter
    include ::profile::scap::dsh

    include ::role::authdns::monitoring

    include ::profile::rsyslog::kafka_shipper

    if os_version('debian >= stretch') {

        class { '::httpd::mpm':
            mpm => 'prefork'
        }

        $httpd_modules = ['headers', 'rewrite', 'authnz_ldap', 'authn_file', 'cgi', 'ssl']

    } else {

        $httpd_modules = ['headers', 'rewrite', 'authnz_ldap', 'authn_file', 'cgi', 'ssl', 'php5']
    }

    class { '::httpd':
        modules => $httpd_modules,
    }
}
