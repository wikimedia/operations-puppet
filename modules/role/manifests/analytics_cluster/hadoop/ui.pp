# Class: role::analytics_cluster::hadoop::ui
#
# Hadoop GUIs.  Currently hue and yarn resourcemanager web interfaces.
#
class role::analytics_cluster::hadoop::ui {
    system::role { 'analytics_cluster::hadoop::ui':
        description => 'Hadoop GUIs: Hue and Yarn ResourceManager web interfaces'
    }

    # include ::profile::hue

    # yarn.wikimedia.org
    include ::profile::hadoop::yarn_proxy

    include ::profile::base::firewall
    include standard
}