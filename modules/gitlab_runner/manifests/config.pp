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
)
{

    file {'/etc/gitlab-runner/config.toml':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('gitlab_runner/config.toml.erb'),
        notify  => Exec['gitlab-runner-restart'],
    }

    exec { 'gitlab-runner-restart':
        user        => 'root',
        command     => '/usr/bin/gitlab-runner restart',
        onlyif      => "/usr/bin/gitlab-runner list 2>&1 | /bin/grep -q '^${runner_name} '",
        refreshonly =>  true,
    }

}
