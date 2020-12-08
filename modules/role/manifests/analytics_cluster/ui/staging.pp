# Class: role::analytics_cluster::superset::staging
#
#
class role::analytics_cluster::ui::staging {
    system::role { 'analytics_cluster::ui::staging':
        description => 'Superset/Turnilo web GUI for analytics dashboards (staging environment)'
    }

    include ::profile::superset
    include ::profile::druid::turnilo
    include ::profile::base::firewall
    include ::profile::standard
    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs
    include ::profile::memcached::instance
}
