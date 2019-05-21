#
class role::netinsights {
    include ::profile::base::firewall
    include ::profile::base::firewall::log
    include ::profile::pmacct
    include ::profile::kafkatee::webrequest::base
}
