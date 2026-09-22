# SPDX-License-Identifier: Apache-2.0
# == Class profile::docker_registry
#
# This provisions a highly available docker registry,
# served at <https://docker-registry.wikimedia.org/>.
#
# See also <https://wikitech.wikimedia.org/wiki/Docker-registry>.
class profile::docker_registry(
    # The following variables might be useful elsewhere too
    String $ci_restricted_user_password = lookup('profile::docker_registry::ci_restricted_user_password'),
    String $kubernetes_user_password = lookup('profile::docker_registry::kubernetes_user_password'),
    String $ci_build_user_password = lookup('profile::docker_registry::ci_build_user_password'),
    String $prod_build_user_password = lookup('profile::docker_registry::prod_build_user_password'),
    String $ml_build_user_password = lookup('profile::docker_registry::ml_build_user_password'),
    String $password_salt = lookup('profile::docker_registry::password_salt'),
    # Which machines are allowed to build images.
    Optional[Array[Stdlib::Host]] $image_builders = lookup('profile::docker_registry::image_builders', { 'default_value' => undef }),
    # Storage configuration
    String $certname = lookup('profile::docker_registry::certname'),
    Array[Cfssl::Common_name] $alt_names = lookup('profile::docker_registry::alt_names'),
    Optional[Stdlib::Host] $redis_host = lookup('profile::docker_registry::redis_host', { 'default_value' => undef }),
    Optional[Stdlib::Port] $redis_port = lookup('profile::docker_registry::redis_port', { 'default_value' => undef }),
    Optional[String] $redis_password = lookup('profile::docker_registry::redis_password', { 'default_value' => undef }),
    Optional[String] $docker_registry_shared_secret = lookup('profile::docker_registry::shared_secret', { 'default_value' => undef }),
    Boolean $registry_read_only_mode = lookup('profile::docker_registry::read_only_mode', { 'default_value' => false }),
    Array[Stdlib::Host] $deployment_hosts = lookup('deployment_hosts', { 'default_value' => [] }),
    Boolean $nginx_auth_cache = lookup('profile::docker_registry::nginx_auth_cache', { 'default_value' => true }),
    # Hosts allowed to authenticate using JSON Web Tokens issued by our GitLab instance
    Array[Stdlib::IP::Address] $jwt_allowed_ips = lookup('profile::docker_registry::jwt_allowed_ips', { 'default_value' => [] }),
    # Which k8s clusters should be able to pull restricted images
    Array[String] $authorized_k8s_clusters = lookup('profile::docker_registry::authorized_k8s_clusters', { 'default_value' => [] }),
    Optional[Integer] $catalog_maxentries = lookup('profile::docker_registry::catalog_maxentries', { 'default_value' => 50}),
    Hash[String, Hash] $apus_credentials = lookup('profile::ceph::s3::client::apus_keys'),
) {
    require network::constants
    # Hiera configurations
    if !$image_builders {
        $builders = $deployment_hosts
    } else {
        $builders = $image_builders
    }

    class { 'docker_registry': }

    # Registry instance holding the MediaWiki restricted images, using S3 as storage.
    docker_registry::instance { 'restricted':
        log_level              => 'debug', # Temporary for T394476
        backend_config         => {
            accesskey                  => $apus_credentials['docker-registry']['access_key'],
            secretkey                  => $apus_credentials['docker-registry']['secret_key'],
            bucket                     => 'registry-restricted', # The bucket should be around beforehand
            regionendpoint             => 'https://apus.discovery.wmnet',
            secure                     => true, # use HTTPS
            encrypt                    => false, # but don't encrypt the data
            region                     => 'us-west-1', # This is useless but required
            chunksize                  => 104857600, # Chunk size for the S3 Multipart upload.
            multipartcopychunksize     => 104857600, # Chunk size for the S3 Multipart Copy upload.
            multipartcopythresholdsize => 209715200, # Threshold to enable/disable S3 Multipart.
            loglevel                   => 'debug', # Temporary for T394476
            # Valid values are: off (default), debug, debugwithsigning, debugwithhttpbody, debugwithrequestretries,
            # debugwithrequesterrors and debugwitheventstreambody
            # loglevel  => 'off',
        },
        redirect_backend       => false,  # https://phabricator.wikimedia.org/T394476#11508332
        redis_config           => {
            addr     => "${redis_host}:${redis_port}",
            password => $redis_password,
            db       => 1,
        },
        registry_shared_secret => $docker_registry_shared_secret,
        catalog_maxentries     => $catalog_maxentries,
        port                   => 5002,
        debug_port             => 5003,
    }

    # Registry instance holding the ML base and service images, using S3 as storage.
    # The rationale of having a separate instance for ML is that the team will likely
    # need to push bigger layers for their images in the future.
    docker_registry::instance { 'ml':
        backend_config         => {
            accesskey      => $apus_credentials['docker-registry']['access_key'],
            secretkey      => $apus_credentials['docker-registry']['secret_key'],
            bucket         => 'registry-ml', # The bucket should be around beforehand
            regionendpoint => 'https://apus.discovery.wmnet',
            secure         => true, # use HTTPS
            encrypt        => false, # but don't encrypt the data
            region         => 'us-west-1', # This is useless but required
            # Valid values are: off (default), debug, debugwithsigning, debugwithhttpbody, debugwithrequestretries,
            # debugwithrequesterrors and debugwitheventstreambody
            # loglevel  => 'off',
        },
        redirect_backend       => false,  # https://phabricator.wikimedia.org/T394476#11508332
        redis_config           => {
            addr     => "${redis_host}:${redis_port}",
            password => $redis_password,
            db       => 2,
        },
        registry_shared_secret => $docker_registry_shared_secret,
        catalog_maxentries     => $catalog_maxentries,
        port                   => 5004,
        debug_port             => 5005,
    }

    # Registry instance holding the Releng's images used for CI, using S3 as storage.
    docker_registry::instance { 'releng':
        backend_config         => {
            accesskey      => $apus_credentials['docker-registry']['access_key'],
            secretkey      => $apus_credentials['docker-registry']['secret_key'],
            bucket         => 'registry-releng', # The bucket should be around beforehand
            regionendpoint => 'https://apus.discovery.wmnet',
            secure         => true, # use HTTPS
            encrypt        => false, # but don't encrypt the data
            region         => 'us-west-1', # This is useless but required
            # Valid values are: off (default), debug, debugwithsigning, debugwithhttpbody, debugwithrequestretries,
            # debugwithrequesterrors and debugwitheventstreambody
            # loglevel  => 'off',
        },
        redirect_backend       => false,  # https://phabricator.wikimedia.org/T394476#11508332
        redis_config           => {
            addr     => "${redis_host}:${redis_port}",
            password => $redis_password,
            db       => 3,
        },
        registry_shared_secret => $docker_registry_shared_secret,
        catalog_maxentries     => $catalog_maxentries,
        port                   => 5006,
        debug_port             => 5007,
    }

    # Main instance holding the images running on Kubernetes and few misc prod systems, using S3 as storage.
    docker_registry::instance { 'main':
        backend_config         => {
            accesskey      => $apus_credentials['docker-registry']['access_key'],
            secretkey      => $apus_credentials['docker-registry']['secret_key'],
            bucket         => 'registry-main', # The bucket should be around beforehand
            regionendpoint => 'https://apus.discovery.wmnet',
            secure         => true, # use HTTPS
            encrypt        => false, # but don't encrypt the data
            region         => 'us-west-1', # This is useless but required
            # Valid values are: off (default), debug, debugwithsigning, debugwithhttpbody, debugwithrequestretries,
            # debugwithrequesterrors and debugwitheventstreambody
            # loglevel  => 'off',
        },
        redirect_backend       => false,  # https://phabricator.wikimedia.org/T394476#11508332
        redis_config           => {
            addr     => "${redis_host}:${redis_port}",
            password => $redis_password,
            db       => 4,
        },
        registry_shared_secret => $docker_registry_shared_secret,
        catalog_maxentries     => $catalog_maxentries,
        port                   => 5008,
        debug_port             => 5009,
    }

    $k8s_groups = k8s::fetch_cluster_groups()
    # Get a list of all nodes (without control planes) in the authorized clusters
    $kubernetes_hosts = $authorized_k8s_clusters.map |$cluster_name| {
        $k8s_groups[$cluster_name].values.map |$x| {
            $x['cluster_nodes'].filter |$n| { !($n in $x['control_plane_nodes']) }
        }
    }.flatten.unique

    # Nginx frontend
    $ssl_paths = profile::pki::get_cert('discovery2026', $certname, {
        'notify_services' => ['nginx'],
        'outdir'          => '/etc/nginx/ssl',
        'hosts'           => $alt_names,
    })
    class { 'sslcert::dhparam': }
    class { 'docker_registry::web':
        ci_restricted_user_password => $ci_restricted_user_password,
        kubernetes_user_password    => $kubernetes_user_password,
        ci_build_user_password      => $ci_build_user_password,
        prod_build_user_password    => $prod_build_user_password,
        ml_build_user_password      => $ml_build_user_password,
        password_salt               => $password_salt,
        allow_push_from             => $image_builders,
        ssl_settings                => ssl_ciphersuite('nginx', 'mid'),
        ssl_paths                   => $ssl_paths,
        read_only_mode              => $registry_read_only_mode,
        nginx_auth_cache            => $nginx_auth_cache,
        deployment_hosts            => $deployment_hosts,
        kubernetes_hosts            => $kubernetes_hosts,
        jwt_allowed_ips             => $jwt_allowed_ips,
        # Note: the image_tag_targets order is relevan for the homepage builder python script,
        # that displays all tags related to an image name found on the last scanned distribution endpoint.
        # For example, if image "batman" has tags 1 2 3 on localhost:5000, and 4 5 6 on localhost:5006,
        # the homepage builder will display only 4 5 6.
        image_tag_targets           => 'localhost:5004 localhost:5006 localhost:5008',
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

    prometheus::blackbox::check::http { $certname:
        server_name        => $certname,
        path               => '/v2/trixie/manifests/latest',
        req_headers        => { 'Accept' => 'application/vnd.docker.distribution.manifest.v2+json'},
        body_regex_matches => ['schemaVersion'],
        team               => 'sre',
        severity           => 'critical',
        probe_runbook      => 'https://wikitech.wikimedia.org/wiki/Docker',
        ip_families        => ['ip4'],
    }

    prometheus::blackbox::check::http { 'docker-registry-restricted-health':
        server_name        => $certname,
        port               => 5003,
        path               => '/debug/health',
        body_regex_matches => ['^\{\}$'],
        team               => 'sre',
        severity           => 'critical',
        probe_runbook      => 'https://wikitech.wikimedia.org/wiki/Docker',
        ip_families        => ['ip4'],
    }

    prometheus::blackbox::check::http { 'docker-registry-ml-health':
        server_name        => $certname,
        port               => 5005,
        path               => '/debug/health',
        body_regex_matches => ['^\{\}$'],
        team               => 'sre',
        severity           => 'critical',
        probe_runbook      => 'https://wikitech.wikimedia.org/wiki/Docker',
        ip_families        => ['ip4'],
    }

    prometheus::blackbox::check::http { 'docker-registry-releng-health':
        server_name        => $certname,
        port               => 5007,
        path               => '/debug/health',
        body_regex_matches => ['^\{\}$'],
        team               => 'sre',
        severity           => 'critical',
        probe_runbook      => 'https://wikitech.wikimedia.org/wiki/Docker',
        ip_families        => ['ip4'],
    }

    prometheus::blackbox::check::http { 'docker-registry-main-health':
        server_name        => $certname,
        port               => 5009,
        path               => '/debug/health',
        body_regex_matches => ['^\{\}$'],
        team               => 'sre',
        severity           => 'critical',
        probe_runbook      => 'https://wikitech.wikimedia.org/wiki/Docker',
        ip_families        => ['ip4'],
    }
}
