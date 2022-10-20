# SPDX-License-Identifier: Apache-2.0
class gitlab_runner::config (
    Stdlib::Absolutepath     $directory               = '/etc/gitlab-runner',
    Integer                  $concurrent              = 3,
    String                   $docker_image            = 'docker-registry.wikimedia.org/buster:latest',
    String                   $docker_network          = 'gitlab-runner',
    Wmflib::Ensure           $ensure_buildkitd        = 'present',
    Hash                     $environment             = {},
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
