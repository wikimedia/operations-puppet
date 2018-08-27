# Class: role::analytics_cluster::hadoop::ui
#
# Hadoop GUIs.  Currently hue and yarn resourcemanager web interfaces.
#
class role::analytics_cluster::hadoop::ui {
    system::role { 'analytics_cluster::hadoop::ui':
        description => 'Hadoop GUIs: Hue and Yarn ResourceManager web interfaces'
    }

    # hue.wikimedia.org
    #
    # NOTE: We currently (2018-08) use Cloudera's Jessie .deb packages on
    # Debian Stretch.  This usually is fine, since most CDH packages are
    # JVM based.  However, hue is a Python Django app, and has non JVM dependencies.
    # 2 of its dependencies are no longer available in Debian Stretch:
    # - libmysqlclient18
    # - libssl1.0.0
    # To work around this, both libmysqlclient18 and libssl1.0.0 have been manually
    # downloaded and installed (dpkg -i) on analytics-tool1001.
    include ::profile::hue

    # yarn.wikimedia.org
    include ::profile::hadoop::yarn_proxy

    include ::profile::base::firewall
    include standard
}
