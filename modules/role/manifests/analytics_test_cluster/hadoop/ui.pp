# Class: role::analytics_test_cluster::hadoop::ui
#
# Hadoop GUIs.  Currently hue and yarn resourcemanager web interfaces.
#
class role::analytics_test_cluster::hadoop::ui {
    system::role { 'analytics_cluster::hadoop::ui':
        description => 'Hadoop GUIs: Hue and Yarn ResourceManager web interfaces'
    }

    include ::profile::java

    # Test cluster setup uses LDAP (in contrast to the prod setup with CAS)
    include ::profile::hadoop::yarn_proxy_testcluster

    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs

    include ::profile::firewall
    include ::profile::base::production
}
