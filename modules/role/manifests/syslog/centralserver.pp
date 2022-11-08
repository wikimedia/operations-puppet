# == Class role::syslog::centralserver
#
# Setup rsyslog as a receiver of cluster wide syslog messages.
#
class role::syslog::centralserver {

    system::role { 'syslog::centralserver':
        description => 'Central syslog server and web requests debugging'
    }

    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::backup::host
    include ::profile::syslog::centralserver
    include ::profile::bird::anycast
    include ::profile::kafkatee::webrequest::ops
    include ::profile::netconsole::server
    include ::profile::benthos

    # https://phabricator.wikimedia.org/T199406
    include ::toil::rsyslog_tls_remedy # lint:ignore:wmf_styleguide
}
