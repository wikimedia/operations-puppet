# Class: role::analytics_cluster::turnilo
#
class role::analytics_cluster::turnilo {
    system::role { 'analytics_cluster::turnilo':
        description => 'Turnilo web GUI for Druid'
    }

    include ::profile::druid::turnilo
    include ::profile::druid::turnilo::proxy
    include ::profile::tlsproxy::envoy
    include ::profile::base::firewall
    include ::profile::standard
}
