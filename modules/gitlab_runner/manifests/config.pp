class gitlab_runner::config (
    Integer             $concurrent              = 3,
    String              $docker_image            = 'docker-registry.wikimedia.org/buster:latest',
    Stdlib::HTTPSUrl    $gitlab_url              = 'https://gitlab.wikimedia.org/',
    String              $runner_name             = 'GitLab Runner',
    Boolean             $enable_exporter         = false,
    Stdlib::IP::Address $exporter_listen_address = '127.0.0.1',
    Integer             $exporter_listen_port    = 9252,
    Integer             $check_interval          = 3,
    Integer             $session_timeout         = 1800,
    String              $gitlab_runner_user      = 'gitlab-runner',

) {

    # Setup config template which is used while registering new runners
    file {'/etc/gitlab-runner/config-template.toml':
        owner   => $gitlab_runner_user,
        mode    => '0400',
        content => template('gitlab_runner/config-template.toml.erb'),
        require => Package['gitlab-runner'],
    }

    # config.toml configuration file has different path for non-root users
    $config_path = $gitlab_runner_user ? {
        'root' => '/etc/gitlab-runner',
        default => "/home/${gitlab_runner_user}/.gitlab-runner"
    }

    # Believe it or not, there's no config template or CLI to modifying
    # the global concurrent Runner settings.
    file_line { 'gitlab-runner-config-concurrent':
        path    => "${config_path}/config.toml",
        match   => '^concurrent *=',
        line    => "concurrent = ${concurrent}",
        notify  => Systemd::Service['gitlab-runner'],
        require => Package['gitlab-runner'],
    }

    # Believe it or not, there's no config template or CLI to modifying
    # the global Prometheus listener settings.
    file_line { 'gitlab-runner-config-exporter':
        ensure  => $enable_exporter.bool2str('present','absent'),
        path    => "${config_path}/config.toml",
        line    => "listen_address = \"[${exporter_listen_address}]:${exporter_listen_port}\"",
        notify  => Systemd::Service['gitlab-runner'],
        require => Package['gitlab-runner'],
        after   => "concurrent = ${concurrent}", # make sure changes happen in global section
    }

    systemd::service{ 'gitlab-runner':
        ensure         => 'present',
        content        => template('gitlab_runner/gitlab-runner.service.erb'),
        service_params => {'restart' => 'systemctl restart gitlab-runner'},
        override       => true, #override default unit file for non-root user
        require        => Package['gitlab-runner'],
    }
}
