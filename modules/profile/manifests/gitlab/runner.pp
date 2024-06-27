# SPDX-License-Identifier: Apache-2.0
# @summary configure host to be a docker based GitLab runner
# @param ensure Ensure of the resources that support it
# @param concurrent Number of concurrent jobs allowed by this runner.
# @param docker_image Default Docker image to use for job execution
# @param image pull_policy set pull_policy for [runners.docker] setting
# @param docker_volume Use a separate volume for docker data (for use on WMCS)
# @param docker_volume_min Minimum size (Gb) of attached volumes considered for the docker mount.
# @param docker_volume_max Maximum size (Gb) of attached volumes considered for the docker mount.
# @param docker_network Name of the Docker network to provision for the runner.
# @param ensure_docker_network configure dedicated Docker network
# @param docker_settings Docker daemon settings
# @param gitlab_url URL of the GitLab instance on which to register
# @param token Token used to register the runner with the GitLab instance.
# @param environment Environment variables to configure for the GitLab runner.
# @param enable_exporter Enable Prometheus metrics exporter
# @param gitlab_runner_user User which is used to execute gitlab-runner daemon
# @param restrict_firewall Enable default REJECT rule for all egress Docker traffic to wmnet
# @param block_dockerhub Enable REJECT rule for traffic from docker (like buildkitd) to dockerhub
# @param allowed_services List of TCP services (host and port) which can be accessed
#   from Docker with restricted firewall enabled. Only used when restrict_firewall is True.
# @param ensure_buildkitd Whether to provide buildkitd for image building.
# @param buildkitd_image Ref to buildkitd container image.
# @param buildkitd_nameservers Nameservers that buildkitd will use for its executors.
# @param clear_interval Interval for cleanup of docker cache/volumes from old jobs.
# @param enable_clear_cache Enable automatic cleanup of cached/old docker volumes.
# @param enable_webproxy Enable usage of webproxy for buildkit to access external resources.
#   When 'true', uses values from http_proxy, http_proxy and no_proxy.
# @param http_proxy Proxy URL to use for http (requires enable_webproxy=true)
# @param https_proxy Proxy URL to use for https (requires enable_webproxy=true)
# @param no_proxy Domains and addresses that shouldn't go through the proxies
#   (requires enable_webproxy=true)
# @param allowed_images Images which are allowed to be executed in CI containers
# @param allowed_docker_services Images which are allowed to be executed as services
#   parallel to CI jobs
# @param internal_ip_range IPv4 range which is blocked when restrict_firewall=true
# @param enable_registry_proxy run a dedicated docker registry to act as a image proxy
# @param registry_proxy_config config which is passed to docker registry
# @param registry_proxy_image image to execute as the registry
# @param buildkitd_dockerfile_frontend_enabled Enable/disable the Dockerfile frontend
# @param buildkitd_gateway_frontend_enabled Enable/disable the gateway.v0 frontend
# @param buildkitd_allowed_gateway_sources A list of gateway sources that buildkitd will allow. If empty, all are allowed
class profile::gitlab::runner (
    Wmflib::Ensure                              $ensure             = lookup('profile::gitlab::runner::ensure'),
    Integer                                     $concurrent         = lookup('profile::gitlab::runner::concurrent'),
    String                                      $docker_image       = lookup('profile::gitlab::runner::docker_image'),
    Array[String]                               $pull_policy        = lookup('profile::gitlab::runner::pull_policy'),
    Boolean                                     $docker_volume      = lookup('profile::gitlab::runner::docker_volume'),
    Integer                                     $docker_volume_min  = lookup('profile::gitlab::runner::docker_volume_min'),
    Integer                                     $docker_volume_max  = lookup('profile::gitlab::runner::docker_volume_max'),
    String                                      $docker_network     = lookup('profile::gitlab::runner::docker_network'),
    Stdlib::IP::Address                         $docker_subnet      = lookup('profile::gitlab::runner::docker_subnet'),
    Wmflib::Ensure                              $ensure_docker_network = lookup('profile::gitlab::runner::ensure_docker_network'),
    Hash                                        $docker_settings    = lookup('profile::gitlab::runner::docker_settings'),
    String                                      $docker_gc_interval = lookup('profile::gitlab::runner::docker_gc_interval'),
    Integer                                     $docker_gc_timeout  = lookup('profile::gitlab::runner::docker_gc_timeout'),
    String                                      $docker_gc_images_high_water_mark  = lookup('profile::gitlab::runner::docker_gc_images_high_water_mark'),
    String                                      $docker_gc_images_low_water_mark   = lookup('profile::gitlab::runner::docker_gc_images_low_water_mark'),
    String                                      $docker_gc_volumes_high_water_mark = lookup('profile::gitlab::runner::docker_gc_volumes_high_water_mark'),
    String                                      $docker_gc_volumes_low_water_mark  = lookup('profile::gitlab::runner::docker_gc_volumes_low_water_mark'),
    Stdlib::HTTPSUrl                            $gitlab_url         = lookup('profile::gitlab::runner::gitlab_url'),
    String                                      $token              = lookup('profile::gitlab::runner::token'),
    Wmflib::POSIX::Variables                    $environment        = lookup('profile::gitlab::runner::environment'),
    Boolean                                     $enable_exporter    = lookup('profile::gitlab::runner::enable_exporter', {default_value => false}),
    String                                      $gitlab_runner_user = lookup('profile::gitlab::runner::user'),
    Boolean                                     $restrict_firewall  = lookup('profile::gitlab::runner::restrict_firewall'),
    Boolean                                     $block_dockerhub    = lookup('profile::gitlab::runner::block_dockerhub'),
    Hash[String, Gitlab_runner::AllowedService] $allowed_services   = lookup('profile::gitlab::runner::allowed_services'),
    Wmflib::Ensure                              $ensure_buildkitd   = lookup('profile::gitlab::runner::ensure_buildkitd'),
    String                                      $buildkitd_image    = lookup('profile::gitlab::runner::buildkitd_image'),
    Array[Stdlib::Host]                         $buildkitd_nameservers = lookup('profile::gitlab::runner::buildkitd_nameservers'),
    Systemd::Timer::Schedule                    $clear_interval     = lookup('profile::gitlab::runner::clear_interval'),
    Boolean                                     $enable_clear_cache = lookup('profile::gitlab::runner::enable_clear_cache'),
    Boolean                                     $enable_webproxy    = lookup('profile::gitlab::runner::enable_webproxy'),
    Optional[String]                            $http_proxy         = lookup('profile::gitlab::runner::http_proxy'),
    Optional[String]                            $https_proxy        = lookup('profile::gitlab::runner::https_proxy'),
    Optional[String]                            $no_proxy           = lookup('profile::gitlab::runner::no_proxy'),
    Array[String]                               $allowed_images     = lookup('profile::gitlab::runner::allowed_images'),
    Array[String]                               $allowed_docker_services = lookup('profile::gitlab::runner::allowed_docker_services'),
    Stdlib::IP::Address::V4::CIDR               $internal_ip_range  = lookup('profile::gitlab::runner::internal_ip_range'),
    Optional[String]                            $buildkitd_gckeepstorage = lookup('profile::gitlab::runner::buildkitd_gckeepstorage'),
    Boolean                                     $enable_registry_proxy = lookup('profile::gitlab::runner::enable_registry_proxy'),
    Hash                                        $registry_proxy_environment = lookup('profile::gitlab::runner::registry_proxy_environment'),
    String                                      $registry_proxy_image = lookup('profile::gitlab::runner::registry_proxy_image'),
    Optional[Boolean]                           $buildkitd_dockerfile_frontend_enabled = lookup('profile::gitlab::runner::buildkitd_dockerfile_frontend_enabled', {default_value => true}),
    Optional[Boolean]                           $buildkitd_gateway_frontend_enabled = lookup('profile::gitlab::runner::buildkitd_gateway_frontend_enabled', {default_value => true}),
    Optional[Array[String]]                     $buildkitd_allowed_gateway_sources = lookup('profile::gitlab::runner::buildkitd_allowed_gateway_sources', {default_value => []}),
) {
    class { 'docker::configuration':
        settings => $docker_settings,
    }

    ensure_packages('apparmor')

    class { 'docker':
        package_name => 'docker.io',
    }

    if $docker_volume {
        cinderutils::ensure { '/var/lib/docker':
            min_gb        => $docker_volume_min,
            max_gb        => $docker_volume_max,
            mount_point   => '/var/lib/docker',
            mount_mode    => '711',
            mount_options => 'discard,defaults',
            before        => Class['docker'],
        }
    }

    docker::network { $docker_network:
        ensure => $ensure_docker_network,
        subnet => $docker_subnet,
        before => Service['ferm'],
    }

    class { 'gitlab_runner::firewall':
        subnet            => $docker_subnet,
        restrict_firewall => $restrict_firewall,
        block_dockerhub   => $block_dockerhub,
        allowed_services  => $allowed_services,
        internal_ip_range => $internal_ip_range,
    }

    # install docker registry to mirror images locally
    $ensure_registry_proxy = $enable_registry_proxy.bool2str('present','absent')
    class { 'gitlab_runner::registry':
        ensure      => $ensure_registry_proxy,
        require     => Class['docker'],
        environment => $registry_proxy_environment,
        image       => $registry_proxy_image,
  }

    if $gitlab_runner_user != 'root' {

        # setup dedicated gitlab-runner user
        wmflib::dir::mkdir_p(
            ["/home/${gitlab_runner_user}/.${gitlab_runner_user}"],
            {owner => $gitlab_runner_user},
        )
        systemd::sysuser { $gitlab_runner_user:
            description       => 'used by gitlab-runner',
            home_dir          => "/home/${gitlab_runner_user}",
            additional_groups => ['docker'],
        }

        # grant read-only access to /etc/gitlab-runner folder
        file { '/etc/gitlab-runner/':
            ensure => 'directory',
            owner  => $gitlab_runner_user,
            mode   => '0400',
        }
    }

    apt::package_from_component{ 'gitlab-runner':
        component => 'thirdparty/gitlab-runner',
        require   =>  Class['docker'],
    }

    class { 'docker::gc':
        ensure                  => $ensure,
        volume_filter           => 'label:com.gitlab.gitlab-runner.type==cache',
        interval                => $docker_gc_interval,
        timeout                 => $docker_gc_timeout,
        images_high_water_mark  => $docker_gc_images_high_water_mark,
        images_low_water_mark   => $docker_gc_images_low_water_mark,
        volumes_high_water_mark => $docker_gc_volumes_high_water_mark,
        volumes_low_water_mark  => $docker_gc_volumes_low_water_mark,
    }

    $runner_name = "${::hostname}.${::domain}"

    $exporter_listen_address = $::realm ? {
        'production' => $facts['ipaddress6'], # export metrics on IPv6 in production
        default      => $facts['ipaddress'],  # export metrics on IPv4 everywhere else
    }

    $config_dir = $gitlab_runner_user ? {
        'root'  => '/etc/gitlab-runner',
        default => "/home/${gitlab_runner_user}/.gitlab-runner"
    }

    # Define common proxy environment variables for both buildkitd and jobs
    # that are executed by the runner
    # See https://wikitech.wikimedia.org/wiki/HTTP_proxy
    $proxy_variables = $enable_webproxy ? {
        true    => {
            'http_proxy'  => $http_proxy,
            'https_proxy' => $https_proxy,
            'no_proxy'    => $no_proxy,
            'HTTP_PROXY'  => $http_proxy,
            'HTTPS_PROXY' => $https_proxy,
            'NO_PROXY'    => $no_proxy,
        }.filter |$k,$v| { $v != undef },
        default =>  {},
    }

    if $ensure == 'present' {

        exec { 'gitlab-register-runner':
            user    => $gitlab_runner_user,
            command => @("CMD"/L$)
                /usr/bin/gitlab-runner register \
                --config "${config_dir}/registration.toml" \
                --non-interactive \
                --name "${runner_name}" \
                --url "${gitlab_url}" \
                --token "${token}" \
                --executor "docker" \
                --docker-image "${docker_image}"
                |- CMD
            ,
            unless  => "/usr/bin/gitlab-runner list 2>&1 | /bin/grep -q '^${runner_name}'",
            require => [Apt::Package_from_component['gitlab-runner'], Exec['gitlab-clear-registration-toml']],
            notify  => Exec['gitlab-runner-merge-configs'],
        }

        # registration.toml has to be cleared, otherwise old and new runner run simultaneously
        exec { 'gitlab-clear-registration-toml':
            user    => $gitlab_runner_user,
            command => "/usr/bin/truncate -s 0 ${config_dir}/registration.toml",
            unless  => "/usr/bin/gitlab-runner list 2>&1 | /bin/grep -q '^${runner_name}'",
            before  =>  Exec['gitlab-register-runner'],
        }

        class { 'gitlab_runner::config':
            directory               => $config_dir,
            concurrent              => $concurrent,
            docker_image            => $docker_image,
            pull_policy             => $pull_policy,
            docker_network          => $docker_network,
            ensure_buildkitd        => $ensure_buildkitd,
            environment             => $environment + $proxy_variables,
            gitlab_url              => $gitlab_url,
            runner_name             => $runner_name,
            exporter_listen_address => $exporter_listen_address,
            enable_exporter         => $enable_exporter,
            gitlab_runner_user      => $gitlab_runner_user,
            require                 => Docker::Network[$docker_network],
            allowed_images          => $allowed_images,
            allowed_docker_services => $allowed_docker_services,
        }
    } else {
        exec { 'gitlab-unregister-runner':
            user    => $gitlab_runner_user,
            command => "/usr/bin/gitlab-runner unregister --name '${runner_name}'",
            onlyif  => "/usr/bin/gitlab-runner list 2>&1 | /bin/grep -q '^${runner_name}'",
            before  =>  Package['gitlab-runner'],
        }
    }

    class { 'buildkitd':
        ensure                      => $ensure_buildkitd,
        network                     => $docker_network,
        image                       => $buildkitd_image,
        nameservers                 => $buildkitd_nameservers,
        environment                 => $proxy_variables,
        gckeepstorage               => $buildkitd_gckeepstorage,
        dockerfile_frontend_enabled => $buildkitd_dockerfile_frontend_enabled,
        gateway_frontend_enabled    => $buildkitd_gateway_frontend_enabled,
        allowed_gateway_sources     => $buildkitd_allowed_gateway_sources,
        require                     => Docker::Network[$docker_network],
    }

    $ensure_clear_cache = $enable_clear_cache.bool2str('present','absent')
    systemd::timer::job { 'clear-docker-cache':
        ensure      => $ensure_clear_cache,
        user        => 'root',
        description => 'Clear docker cache/volumes',
        command     => '/usr/share/gitlab-runner/clear-docker-cache',
        interval    => $clear_interval,
        require     =>  Package['gitlab-runner'],
    }

    file { '/usr/local/bin/pool':
        ensure => file,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/gitlab_runner/pool.sh',
    }

    file { '/usr/local/bin/depool':
        ensure => file,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/gitlab_runner/depool.sh',
    }
}
