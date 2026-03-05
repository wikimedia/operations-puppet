# SPDX-License-Identifier: Apache-2.0
# @summary configure gitlab-runner config.toml and systemd unit file
# @param directory Location of config files and tokens.
# @param concurrent Number of jobs that can run concurrently.
# @param docker_image Default Docker image used for jobs.
# @param pull_policy Docker image pull policies (e.g., 'always').
# @param docker_network Docker network to attach containers to.
# @param ensure_buildkitd Whether buildkitd should be ensured (e.g., 'present' or 'absent').
# @param environment Environment variables passed to the runner as a hash.
# @param gitlab_url URL of the GitLab instance the runner should connect to.
# @param runner_name Name to assign to the runner.
# @param enable_exporter Whether to enable Prometheus exporter for metrics.
# @param exporter_listen_address IP address the exporter listens on.
# @param exporter_listen_port Port the exporter listens on.
# @param check_interval Time (in seconds) between GitLab job checks.
# @param session_timeout Timeout (in seconds) for job sessions.
# @param gitlab_runner_user System user under which the runner service runs.
# @param allowed_images List of Docker images that are allowed to be used.
# @param allowed_docker_services List of allowed Docker services.
# @param output_limit Maximum size (in KB) of job output logs.
class gitlab_runner::config (
    Stdlib::Absolutepath     $directory               = '/etc/gitlab-runner',
    Integer                  $concurrent              = 3,
    String                   $docker_image            = 'docker-registry.wikimedia.org/bookworm:latest',
    Array[String]            $pull_policy             = ['always'],
    String                   $docker_network          = 'gitlab-runner',
    Wmflib::Ensure           $ensure_buildkitd        = 'present',
    Wmflib::POSIX::Variables $environment             = {},
    Stdlib::HTTPSUrl         $gitlab_url              = 'https://gitlab.wikimedia.org/',
    String                   $runner_name             = 'GitLab Runner',
    Boolean                  $enable_exporter         = false,
    Stdlib::IP::Address      $exporter_listen_address = '127.0.0.1',
    Integer                  $exporter_listen_port    = 9252,
    Integer                  $check_interval          = 3,
    Integer                  $session_timeout         = 1800,
    String                   $gitlab_runner_user      = 'gitlab-runner',
    Array[String]            $allowed_images          = [],
    Array[String]            $allowed_docker_services = [],
    Integer                  $output_limit            = 4096,
) {
    ensure_packages('python3-toml')

    # We can't use a GitLab runner config template here because the runner
    # will not pickup changes to it after registration. Instead we'll manage
    # a config file directly and then merge it and the config created during
    # registration ourselves.
    #
    $registration_config = "${directory}/registration.toml"
    $managed_config = "${directory}/managed.toml"
    $runtime_config = "${directory}/config.toml"
    $merger = '/usr/local/bin/gitlab-runner-merge-configs.py'

    file { $managed_config:
        owner   => $gitlab_runner_user,
        mode    => '0400',
        content => template('gitlab_runner/config.toml.erb'),
        require => Package['gitlab-runner'],
        notify  => Exec['gitlab-runner-merge-configs'],
    }

    file { $runtime_config:
        owner => $gitlab_runner_user,
        mode  => '0600',
    }

    file { $merger:
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/gitlab_runner/gitlab-runner-merge-configs.py',
    }

    exec { 'gitlab-runner-merge-configs':
        user        => $gitlab_runner_user,
        command     => "${merger} '${registration_config}' '${managed_config}' > '${runtime_config}'",
        refreshonly => true,
        notify      => Systemd::Service['gitlab-runner'],
        require     => [
            File[$runtime_config],
            File[$managed_config],
        ],
    }

    systemd::service{ 'gitlab-runner':
        ensure         => 'present',
        content        => template('gitlab_runner/gitlab-runner.service.erb'),
        service_params => {'restart' => 'systemctl restart -s SIGQUIT gitlab-runner'},
        override       => true, #override default unit file for non-root user
    }
}
