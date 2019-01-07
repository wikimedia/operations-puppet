# Class: role::analytics_test_cluster::turnilo
#
class role::analytics_test_cluster::turnilo {
    system::role { 'analytics_test_cluster::turnilo':
        description => 'Turnilo web GUI for Druid'
    }

    include ::profile::druid::turnilo
    include ::profile::base::firewall
    include standard
}
