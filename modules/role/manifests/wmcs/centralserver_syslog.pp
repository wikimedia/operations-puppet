# == Class role::wmcs::centralserver_syslog
#
# Setup rsyslog as a receiver of cluster wide syslog messages.
#
class role::wmcs::centralserver_syslog {
    system::role { 'wmcs::centralserver_syslog':
        description => 'Central syslog server (Wikimedia Cloud)'
    }

    include ::profile::base::labs
    include ::profile::base::firewall

    include ::profile::syslog::centralserver

    # https://phabricator.wikimedia.org/T199406
    include ::toil::rsyslog_tls_remedy # lint:ignore:wmf_styleguide
}
