# SPDX-License-Identifier: Apache-2.0
# == Class profile::docker_registry_ha::registry
#
# This provisions a highly available docker registry,
# served at <https://docker-registry.wikimedia.org/>.
#
# See also <https://wikitech.wikimedia.org/wiki/Docker-registry>.

class profile::docker_registry_ha::registry(
    # The following variables might be useful elsewhere too
    String $ci_restricted_user_password = lookup('profile::docker_registry_ha::ci_restricted_user_password'),
    String $kubernetes_user_password = lookup('profile::docker_registry_ha::kubernetes_user_password'),
    String $ci_build_user_password = lookup('profile::docker_registry_ha::ci_build_user_password'),
    String $prod_build_user_password = lookup('profile::docker_registry_ha::prod_build_user_password'),
    String $password_salt = lookup('profile::docker_registry_ha::password_salt'),
    # Which machines are allowed to build images.
    Optional[Array[Stdlib::Host]] $image_builders = lookup('profile::docker_registry_ha::registry::image_builders', { 'default_value' => undef }),
    # Storage configuration
    String $certname = lookup('profile::docker_registry_ha::registry::certname'),
    Array[Cfssl::Common_name] $alt_names = lookup('profile::docker_registry_ha::registry::alt_names'),
    Hash[String, Hash[String, String]] $swift_accounts = lookup('profile::swift::accounts'),
    Stdlib::Httpsurl $swift_auth_url = lookup('profile::docker_registry_ha::registry::swift_auth_url'),
    # By default, the password will be extracted from swift, but can be overridden
    Hash[String, Hash] $global_swift_account_keys = lookup('profile::swift::global_account_keys'),
    Optional[String] $swift_container = lookup('profile::docker_registry_ha::registry::swift_container', { 'default_value' => undef }),
    String $swift_replication_configuration = lookup('profile::docker_registry_ha::registry::swift_replication_configuration'),
    String $swift_replication_key = lookup('profile::docker_registry_ha::registry::swift_replication_key'),
    Optional[String] $swift_password = lookup('profile::docker_registry_ha::registry::swift_password', { 'default_value' => undef }),
    Optional[Stdlib::Host] $redis_host = lookup('profile::docker_registry_ha::registry::redis_host', { 'default_value' => undef }),
    Optional[Stdlib::Port] $redis_port = lookup('profile::docker_registry_ha::registry::redis_port', { 'default_value' => undef }),
    Optional[String] $redis_password = lookup('profile::docker_registry_ha::registry::redis_password', { 'default_value' => undef }),
    Optional[String] $docker_registry_shared_secret = lookup('profile::docker_registry_ha::registry::shared_secret', { 'default_value' => undef }),
    Boolean $registry_read_only_mode = lookup('profile::docker_registry_ha::registry::read_only_mode', { 'default_value' => false }),
    Array[Stdlib::Host] $deployment_hosts = lookup('deployment_hosts', { 'default_value' => [] }),
    Boolean $nginx_cache = lookup('profile::docker_registry_ha::registry::nginx_cache', { 'default_value' => true }),
    # Hosts allowed to authenticate using JSON Web Tokens issued by our GitLab instance
    Array[Stdlib::IP::Address] $jwt_allowed_ips = lookup('profile::docker_registry_ha::registry::jwt_allowed_ips', { 'default_value' => [] }),
    # Which k8s clusters should be able to pull restricted images
    Array[String] $authorized_k8s_clusters = lookup('profile::docker_registry_ha::registry::authorized_k8s_clusters', { 'default_value' => [] }),
    Optional[Integer] $catalog_maxentries = lookup('profile::docker_registry_ha::registry::catalog_maxentries', { 'default_value' => 50}),
) {
    # if this looks pretty similar to profile::docker::registry
    # is intended.

    require network::constants
    # Hiera configurations
    if !$image_builders {
        $builders = $deployment_hosts
    } else {
        $builders = $image_builders
    }

    # Nginx frontend
    $ssl_paths = profile::pki::get_cert('discovery', $certname, {
        'notify_services' => ['nginx'],
        'outdir'          => '/etc/nginx/ssl',
        'hosts'           => $alt_names,
    })
    class { 'sslcert::dhparam': }

    $swift_account = $swift_accounts['docker_registry']
    # Get the local site's swift credentials
    $swift_account_keys = $global_swift_account_keys[$::site]
    if !$swift_password {
        $password = $swift_account_keys['docker_registry']
    }
    else {
        $password = $swift_password
    }

    class { 'docker_registry_ha':
        swift_user                      => $swift_account['user'],
        swift_password                  => $password,
        swift_url                       => $swift_auth_url,
        swift_replication_key           => $swift_replication_key,
        swift_replication_configuration => $swift_replication_configuration,
        swift_container                 => $swift_container,
        redis_host                      => $redis_host,
        redis_port                      => $redis_port,
        redis_passwd                    => $redis_password,
        registry_shared_secret          => $docker_registry_shared_secret,
        catalog_maxentries              => $catalog_maxentries,
    }

    $k8s_groups = k8s::fetch_cluster_groups()
    # Get a list of all nodes (without control planes) in the authorized clusters
    $kubernetes_hosts = $authorized_k8s_clusters.map |$cluster_name| {
        $k8s_groups[$cluster_name].values.map |$x| {
            $x['cluster_nodes'].filter |$n| { !($n in $x['control_plane_nodes']) }
        }
    }.flatten.unique

    class { 'docker_registry_ha::web':
        ci_restricted_user_password => $ci_restricted_user_password,
        kubernetes_user_password    => $kubernetes_user_password,
        ci_build_user_password      => $ci_build_user_password,
        prod_build_user_password    => $prod_build_user_password,
        password_salt               => $password_salt,
        allow_push_from             => $image_builders,
        ssl_settings                => ssl_ciphersuite('nginx', 'mid'),
        ssl_paths                   => $ssl_paths,
        read_only_mode              => $registry_read_only_mode,
        nginx_cache                 => $nginx_cache,
        deployment_hosts            => $deployment_hosts,
        kubernetes_hosts            => $kubernetes_hosts,
        jwt_allowed_ips             => $jwt_allowed_ips,
    }

    # T209709
    nginx::status_site { 'status':
        port => 10080,
    }

    ferm::service { 'docker_registry_https':
        proto  => 'tcp',
        port   => 443,
        srange => '$DOMAIN_NETWORKS',
    }

    # Monitoring
    # This will test both nginx and the docker registry application
    monitoring::service { 'check_docker_registry_https':
        description   => 'Docker registry HTTPS interface',
        check_command => "check_https_url_for_string!${::fqdn}!/v2/bullseye/manifests/latest!schemaVersion",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Docker',
    }

    monitoring::service { 'check_docker_registry_https_expiry':
        description   => 'Docker registry HTTPS interface certificate expiry',
        check_command => "check_https_expiry!${facts['networking']['fqdn']}!443",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Docker',
    }

    # This will query /debug/health registry endpoint on 5001 debug server
    monitoring::service { 'check_docker_registry_health':
        description   => 'Docker registry health',
        check_command => "check_http_url_for_regexp_on_port!${::fqdn}:5001!5001!/debug/health!\\\\{\\\\}",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Docker',
    }
}
