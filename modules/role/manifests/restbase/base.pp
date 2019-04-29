# Base role for all restbase roles
#
class role::restbase::base{
    include ::passwords::cassandra
    include ::profile::base::firewall
    include ::profile::standard
    include ::profile::rsyslog::kafka_shipper
    include ::profile::rsyslog::udp_localhost_compat

    include ::profile::cassandra
    include ::profile::restbase
}
