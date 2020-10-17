class role::analytics_cluster::webserver {

    system::role { 'analytics_cluster::webserver':
        description => 'Webserver hosting the main Analytics websites'
    }

    include ::profile::analytics::httpd
    include ::profile::analytics::cluster::gitconfig

    # Temporarily include both nginx and envoy, so that traffic can be maintained
    # without interruption as we switch over.
    include ::profile::tlsproxy::service
    include ::profile::tlsproxy::envoy

    include ::profile::statistics::web

    include ::profile::base::firewall
    include ::profile::standard
}
