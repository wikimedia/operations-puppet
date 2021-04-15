# Class: role::analytics_cluster::hadoop::ui
#
# Hadoop GUIs.  Currently hue and yarn resourcemanager web interfaces.
#
class role::analytics_cluster::hadoop::ui {
    system::role { 'analytics_cluster::hadoop::ui':
        description => 'Hadoop GUIs: Hue ResourceManager web interface'
    }

    include ::profile::java
    include ::profile::hue

    # TLS terminator/proxy for Hue
    include ::profile::tlsproxy::envoy

    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs

    include ::profile::base::firewall
    include ::profile::standard
}
