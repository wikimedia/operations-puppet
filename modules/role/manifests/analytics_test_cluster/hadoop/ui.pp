# Class: role::analytics_test_cluster::hadoop::ui
#
# Hadoop GUIs.  Currently the yarn resourcemanager web interface.
#
class role::analytics_test_cluster::hadoop::ui {
    include profile::java

    # Test cluster setup uses LDAP (in contrast to the prod setup with CAS)
    include profile::hadoop::yarn_proxy_testcluster

    include profile::kerberos::client
    include profile::kerberos::keytabs

    include profile::firewall
    include profile::base::production
}
