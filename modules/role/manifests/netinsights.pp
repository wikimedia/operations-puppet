#
class role::netinsights {
    include ::profile::base::firewall
    include ::profile::pmacct
    include ::profile::rpkicounter
}
