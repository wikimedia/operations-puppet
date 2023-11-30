# == Class role::wmcs::centralserver_syslog
#
# Setup rsyslog as a receiver of cluster wide syslog messages.
#
class role::wmcs::centralserver_syslog {
    system::role { 'wmcs::centralserver_syslog':
        description => 'Central syslog server (Wikimedia Cloud)'
    }

    include ::profile::base::labs
    include ::profile::firewall

    include ::profile::syslog::centralserver
}
