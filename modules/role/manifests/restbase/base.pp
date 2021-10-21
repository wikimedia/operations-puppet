# Base role for all restbase roles
#
class role::restbase::base{
    include ::passwords::cassandra
    include ::profile::base::firewall
    include ::profile::base::production
    include ::profile::rsyslog::udp_localhost_compat

    include ::profile::cassandra
    include ::profile::restbase
}
