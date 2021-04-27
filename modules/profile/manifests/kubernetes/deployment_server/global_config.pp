# Kubernetes global configuration files.
# They include data that's useful to all deployed services.
#
class profile::kubernetes::deployment_server::global_config(
    Hash[String, String] $clusters = lookup('kubernetes_clusters'),
    Hash[String, Any] $general_values=lookup('profile::kubernetes::deployment_server::general', {'default_value' => {}}),
    $general_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
    Array[Profile::Service_listener] $service_listeners = lookup('profile::services_proxy::envoy::listeners', {'default_value' => []}),
    Array[Stdlib::Fqdn] $prometheus_nodes = lookup('prometheus_all_nodes'),
    Array[Mediawiki::SiteCollection] $common_sites = lookup('mediawiki::common_sites'),
    Array[Mediawiki::SiteCollection] $mediawiki_sites = lookup('mediawiki::sites'),
    Optional[Stdlib::Port::User] $fcgi_port = lookup('profile::php_fpm::fcgi_port', {'default_value' => undef}),
    String $fcgi_pool = lookup('profile::mediawiki::fcgi_pool', {'default_value' => 'www'}),
    String $domain_suffix = lookup('mediawiki::web::sites::domain_suffix', {'default_value' => 'org'}),
    Hash[String, Hash] $kafka_clusters = lookup('kafka_clusters'),
) {
    # General directory holding all configurations managed by puppet
    # that are used in helmfiles
    file { $general_dir:
        ensure => directory
    }

    # directory holding private data for services
    # This is only writable by root, and readable by group wikidev
    $general_private_dir = "${general_dir}/private"
    file { $general_private_dir:
        ensure => directory,
        owner  => 'root',
        group  => 'wikidev',
        mode   => '0750'
    }

    # Global data defining the services proxy upstreams
    # Services proxy list of definitions to use by our helm charts.
    # They come from two hiera data structures:
    # - profile::services_proxy::envoy::listeners
    # - service::catalog
    $services_proxy = wmflib::service::fetch()
    $proxies = $service_listeners.map |$listener| {
        $address = $listener['upstream'] ? {
            undef   => "${listener['service']}.discovery.wmnet",
            default => $listener['upstream'],
        }
        $svc = $services_proxy[$listener['service']]
        $upstream_port = $svc['port']
        $encryption = $svc['encryption']
        # To properly enable the networkpolicies, we also need to collect the service IPs
        $ip_addresses = $svc['ip'].map |$k, $v| { $v.values() }.flatten().unique().sort().map |$x| {
            $retval = $x ? {
                Stdlib::IP::Address::V4::Nosubnet => "${x}/32",
                Stdlib::IP::Address::V6::Nosubnet => "${x}/128",
                default                           => $x
            }
            $retval
        }
        $retval = {
            $listener['name'] => {
                'keepalive' => $listener['keepalive'],
                'port' => $listener['port'],
                'http_host' => $listener['http_host'],
                'timeout'   => $listener['timeout'],
                'retry_policy' => $listener['retry'],
                'xfp' => $listener['xfp'],
                'upstream' => {
                    'ips' => $ip_addresses,
                    'address' => $address,
                    'port' => $upstream_port,
                    'encryption' => $encryption,
                }
            }.filter |$key, $val| { $val =~ NotUndef }
        }
    }.reduce({}) |$mem, $val| { $mem.merge($val) }

    $kafka_brokers = $kafka_clusters.map |$cl, $data| {
        $ips = $data['brokers'].keys().map |$n| {ipresolve($n)}
        $retval = {$cl => $ips}
        $retval
    }.reduce({}) | $mem, $val| { $mem.merge($val)}

    # Per-cluster general defaults.
    $clusters.each |String $environment, $dc| {
        $puppet_ca_data = file($facts['puppet_config']['localcacert'])

        $filtered_prometheus_nodes = $prometheus_nodes.filter |$node| { "${dc}.wmnet" in $node }.map |$node| { ipresolve($node) }

        unless empty($filtered_prometheus_nodes) {
            $deployment_config_opts = {
                'tls' => {
                    'telemetry' => {
                        'prometheus_nodes' => $filtered_prometheus_nodes
                    }
                },
                'puppet_ca_crt' => $puppet_ca_data,
            }
        } else {
            $deployment_config_opts = {
                'puppet_ca_crt' => $puppet_ca_data
            }
        }
        # Merge default and environment specific general values with deployment config and service proxies
        $opts = deep_merge($general_values['default'], $general_values[$environment], $deployment_config_opts, {'services_proxy' => $proxies, 'kafka_brokers' => $kafka_brokers})
        file { "${general_dir}/general-${environment}.yaml":
            content => to_yaml($opts),
            mode    => '0444'
        }
    }
    ### MediaWiki-related configurations.
    file { "${general_dir}/mediawiki":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    }
    # Generate the apache-config defining yaml, and save it to
    # $general_dir/mediawiki/httpd.yaml
    $fcgi_proxy = mediawiki::fcgi_endpoint($fcgi_port, $fcgi_pool)
    $all_sites = $mediawiki_sites + $common_sites
    class { '::mediawiki::web::yaml_defs':
        path          => "${general_dir}/mediawiki/httpd.yaml",
        siteconfigs   => $all_sites,
        fcgi_proxy    => $fcgi_proxy,
        domain_suffix => $domain_suffix,
    }
}
