# Class: role::analytics_cluster::hadoop::yarn
#
# Hadoop Yarn UI
#
class role::analytics_cluster::hadoop::yarn {
    system::role { 'analytics_cluster::hadoop::yarn':
        description => 'Hadoop Yarn ResourceManager web interface'
    }

    include ::profile::java

    include ::profile::tlsproxy::service
    include ::profile::tlsproxy::envoy

    include ::profile::hadoop::yarn_proxy

    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs

    include ::profile::base::firewall
    include ::profile::standard
}
