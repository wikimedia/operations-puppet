# Base role for all restbase roles
#
class role::restbase::base{
    include ::passwords::cassandra
    include ::base::firewall
    include ::standard

    include ::profile::cassandra
    include ::profile::restbase
}
