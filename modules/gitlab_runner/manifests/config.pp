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
    Array[Stdlib::Host] $prometheus_nodes        = [],
)
{

    # Setup config template which is used while registering new runners
    file {'/etc/gitlab-runner/config-template.toml':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('gitlab_runner/config-template.toml.erb'),
    }

    # Believe it or not, there's no config template or CLI to modifying
    # the global concurrent Runner settings.
    file_line { 'gitlab-runner-config-concurrent':
        path   => '/etc/gitlab-runner/config.toml',
        match  => '^concurrent *=',
        line   => "concurrent = ${concurrent}",
        notify => Exec['gitlab-runner-restart'],
    }

    # Believe it or not, there's no config template or CLI to modifying
    # the global Prometheus listener settings.
    file_line { 'gitlab-runner-config-exporter':
        ensure => $enable_exporter.bool2str('present','absent'),
        path   => '/etc/gitlab-runner/config.toml',
        line   => "listen_address = \"${exporter_listen_address}:${exporter_listen_port}\"",
        notify => Exec['gitlab-runner-restart'],
    }

    exec { 'gitlab-runner-restart':
        user        => 'root',
        command     => '/usr/bin/gitlab-runner restart',
        onlyif      => "/usr/bin/gitlab-runner list 2>&1 | /bin/grep -q '^${runner_name} '",
        refreshonly =>  true,
    }

    if !empty($prometheus_nodes) {
        # gitlab-runner exports metric and prometheus nodes need access
        $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
        $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

        ferm::service { 'gitlab_runner':
            ensure => $enable_exporter.bool2str('present','absent'),
            proto  => 'tcp',
            port   => $exporter_listen_port,
            srange => $ferm_srange,
        }
    }

}
