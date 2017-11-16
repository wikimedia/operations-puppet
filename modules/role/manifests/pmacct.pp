#
class role::pmacct {
    include ::profile::base::firewall
    include ::profile::pmacct
}
