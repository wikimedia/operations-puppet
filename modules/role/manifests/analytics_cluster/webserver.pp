class role::analytics_cluster::webserver {

    system::role { 'analytics_cluster::webserver':
        description => 'Webserver hosting the main Analytics websites'
    }

    include ::profile::analytics::httpd
    include ::profile::analytics::cluster::gitconfig

    include ::profile::statistics::web

    include ::profile::base::firewall
    include ::profile::standard
}
