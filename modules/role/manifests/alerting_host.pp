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
    include ::role::icinga
    include ::role::tcpircbot
    include ::role::certspotter
    interface::add_ip6_mapped { 'main': }
}
