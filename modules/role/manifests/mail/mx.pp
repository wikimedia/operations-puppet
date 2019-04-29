# filtertags: labs-project-deployment-prep
class role::mail::mx(
    $verp_domains = [
        'wikimedia.org'
    ],
    $verp_post_connect_server = 'meta.wikimedia.org',
    $verp_bounce_post_url = 'api-rw.discovery.wmnet/w/api.php',
    $prometheus_nodes = hiera('prometheus_nodes', []), # lint:ignore:wmf_styleguide
) {
    include ::profile::standard
    include network::constants
    include privateexim::aliases::private
    include ::profile::base::firewall

    system::role { 'mail::mx':
        description => 'Mail router',
    }

    class { '::profile::mail::mx':
        verp_domains             => $verp_domains,
        verp_post_connect_server => $verp_post_connect_server,
        verp_bounce_post_url     => $verp_bounce_post_url,
        prometheus_nodes         => $prometheus_nodes
    }
}
