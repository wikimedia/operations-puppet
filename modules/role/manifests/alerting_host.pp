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
    include ::profile::icinga
    include ::profile::tcpircbot
    include ::profile::certspotter
    include ::role::authdns::monitoring
    include ::standard
    include ::profile::base::firewall
    include ::profile::scap::dsh

    if os_version('debian >= stretch') {
        $php_module = 'php7.0'
    } else {
        $php_module = 'php5'
    }

    class { '::httpd':
        modules => ['headers', 'rewrite', 'authnz_ldap', 'cgi', 'ssl', $php_module],
    }
}
