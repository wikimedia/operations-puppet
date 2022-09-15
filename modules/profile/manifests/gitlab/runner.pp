# @summary configure host to be a docker based GitLab runner
# @param ensure Ensure of the resources that support it
# @param access_level Whether the runner is protected or not. Whenever a runner is protected, it
# picks only jobs created on protected branches or protected tags, and ignores other jobs.
# @param concurrent Number of concurrent jobs allowed by this runner.
# @param docker_image Default Docker image to use for job execution
# @param docker_volume Use a separate volume for docker data (for use on WMCS)
# @param docker_volume_min Minimum size (Gb) of attached volumes considered for the docker mount.
# @param docker_volume_max Maximum size (Gb) of attached volumes considered for the docker mount.
# @param docker_network Name of the Docker network to provision for the runner.
# @param docker_settings Docker daemon settings
# @param gitlab_url URL of the GitLab instance on which to register
# @param locked Whether the runner is locked and can/cannot be enabled for projects
# @param registration_token Token used to register the runner with the GitLab instance.
# @param run_untagged Whether the runner should also run untagged jobs
# @param tags Tags used to schedule matching jobs to this runner
# @param enable_exporter Enable Prometheus metrics exporter
# @param gitlab_runner_user User which is used to execute gitlab-runner daemon
# @param restrict_firewall Enable default REJECT rule for all egress Docker traffic to wmnet
# @param allowed_services List of TCP services (host and port) which can be accessed from Docker
# with restricted firewall enabled. Only used when restrict_firewall is True.
# @param ensure_buildkitd Whether to provide buildkitd for image building.
# @param buildkitd_image Ref to buildkitd container image.
# @param clear_interval Interval for cleanup of docker cache/volumes from old jobs.
# @param enable_clear_cache Enable automatic cleanup of cached/old docker volumes.
# @param enable_webproxy Enable usage of webproxy for buildkit to access external resources
class profile::gitlab::runner (
    Wmflib::Ensure                              $ensure             = lookup('profile::gitlab::runner::ensure'),
    Enum['not_protected', 'ref_protected']      $access_level       = lookup('profile::gitlab::runner::access_level'),
    Integer                                     $concurrent         = lookup('profile::gitlab::runner::concurrent'),
    String                                      $docker_image       = lookup('profile::gitlab::runner::docker_image'),
    Boolean                                     $docker_volume      = lookup('profile::gitlab::runner::docker_volume'),
    Integer                                     $docker_volume_min  = lookup('profile::gitlab::runner::docker_volume_min'),
    Integer                                     $docker_volume_max  = lookup('profile::gitlab::runner::docker_volume_max'),
    String                                      $docker_network     = lookup('profile::gitlab::runner::docker_network'),
    Stdlib::IP::Address                         $docker_subnet      = lookup('profile::gitlab::runner::docker_subnet'),
    Hash                                        $docker_settings    = lookup('profile::gitlab::runner::docker_settings'),
    String                                      $docker_gc_interval = lookup('profile::gitlab::runner::docker_gc_interval'),
    String                                      $docker_gc_images_high_water_mark  = lookup('profile::gitlab::runner::docker_gc_images_high_water_mark'),
    String                                      $docker_gc_images_low_water_mark   = lookup('profile::gitlab::runner::docker_gc_images_low_water_mark'),
    String                                      $docker_gc_volumes_high_water_mark = lookup('profile::gitlab::runner::docker_gc_volumes_high_water_mark'),
    String                                      $docker_gc_volumes_low_water_mark  = lookup('profile::gitlab::runner::docker_gc_volumes_low_water_mark'),
    Stdlib::HTTPSUrl                            $gitlab_url         = lookup('profile::gitlab::runner::gitlab_url'),
    Boolean                                     $locked             = lookup('profile::gitlab::runner::locked'),
    String                                      $registration_token = lookup('profile::gitlab::runner::registration_token'),
    Boolean                                     $run_untagged       = lookup('profile::gitlab::runner::run_untagged'),
    Array[String]                               $tags               = lookup('profile::gitlab::runner::tags'),
    Boolean                                     $enable_exporter    = lookup('profile::gitlab::runner::enable_exporter', {default_value => false}),
    String                                      $gitlab_runner_user = lookup('profile::gitlab::runner::user'),
    Boolean                                     $restrict_firewall  = lookup('profile::gitlab::runner::restrict_firewall'),
    Hash[String, Gitlab_runner::AllowedService] $allowed_services   = lookup('profile::gitlab::runner::allowed_services'),
    Wmflib::Ensure                              $ensure_buildkitd   = lookup('profile::gitlab::runner::ensure_buildkitd'),
    String                                      $buildkitd_image    = lookup('profile::gitlab::runner::buildkitd_image'),
    Systemd::Timer::Schedule                    $clear_interval     = lookup('profile::gitlab::runner::clear_interval'),
    Boolean                                     $enable_clear_cache = lookup('profile::gitlab::runner::enable_clear_cache'),
    Boolean                                     $enable_webproxy    = lookup('profile::gitlab::runner::enable_webproxy'),
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
        ensure => $ensure,
        subnet => $docker_subnet,
    }

    class { 'gitlab_runner::firewall':
        subnet            => $docker_subnet,
        restrict_firewall => $restrict_firewall,
        allowed_services  => $allowed_services,
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
        interval                => $docker_gc_interval,
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

    if $ensure == 'present' {
        $tag_list = join($tags, ',')

        exec { 'gitlab-register-runner':
            user    => $gitlab_runner_user,
            command => @("CMD"/L$)
                /usr/bin/gitlab-runner register \
                --config "${config_dir}/registration.toml" \
                --non-interactive \
                --name "${runner_name}" \
                --url "${gitlab_url}" \
                --registration-token "${registration_token}" \
                --executor "docker" \
                --docker-image "${docker_image}" \
                --tag-list "${tag_list}" \
                --run-untagged="${run_untagged}" \
                --locked="${locked}" \
                --access-level="${access_level}"
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
            docker_network          => $docker_network,
            ensure_buildkitd        => $ensure_buildkitd,
            gitlab_url              => $gitlab_url,
            runner_name             => $runner_name,
            exporter_listen_address => $exporter_listen_address,
            enable_exporter         => $enable_exporter,
            gitlab_runner_user      => $gitlab_runner_user,
            require                 => Docker::Network[$docker_network],
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
        ensure          => $ensure_buildkitd,
        network         => $docker_network,
        image           => $buildkitd_image,
        enable_webproxy => $enable_webproxy,
        require         => Docker::Network[$docker_network],
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
}
