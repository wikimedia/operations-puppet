# SPDX-License-Identifier: Apache-2.0
class gitlab_runner::config (
    Stdlib::Absolutepath $directory               = '/etc/gitlab-runner',
    Integer              $concurrent              = 3,
    String               $docker_image            = 'docker-registry.wikimedia.org/buster:latest',
    String               $docker_network          = 'gitlab-runner',
    Wmflib::Ensure       $ensure_buildkitd        = 'present',
    Stdlib::HTTPSUrl     $gitlab_url              = 'https://gitlab.wikimedia.org/',
    String               $runner_name             = 'GitLab Runner',
    Boolean              $enable_exporter         = false,
    Stdlib::IP::Address  $exporter_listen_address = '127.0.0.1',
    Integer              $exporter_listen_port    = 9252,
    Integer              $check_interval          = 3,
    Integer              $session_timeout         = 1800,
    String               $gitlab_runner_user      = 'gitlab-runner',
) {
    # NOTE we can't use a GitLab runner config template here because the
    # runner will not pickup changes to it after registration, and we can't
    # manage the config file directly because the runner writes its
    # auth token back to the config following registration, so... we have to
    # do this little dance to get the config fully puppetized:
    #  1) have `gitlab-runner register` write its configuration to a separate
    #     file (`registration.toml`) (see profile::gitlab::runner)
    #  2) extract the auth token from `registration.toml` into `token` (see
    #  profile::gitlab::runner)
    #  3) write our own temporary config that contains a `token = "$TOKEN"`
    #     placeholder for the auth token value
    #  4) use `TOKEN=$(cat token) envsubst` to substitute the placeholder with
    #     the auth token value and write the config to `config.toml`


    # write to a temporary config before substituting the $TOKEN variable for
    # the saved auth token
    file { "${directory}/config-without-token.toml":
        owner   => $gitlab_runner_user,
        mode    => '0400',
        content => template('gitlab_runner/config.toml.erb'),
        require => Package['gitlab-runner'],
        notify  => Exec['gitlab-runner-config-subst-token'],
    }

    # substitute the ${TOKEN} variable in the temporary config and write to
    # the final config file
    exec { 'gitlab-runner-config-subst-token':
        user        => $gitlab_runner_user,
        command     => @("CMD"/L$)
            TOKEN="\$(cat '${directory}/auth-token')"
            /usr/bin/envsubst \
            < '${directory}/config-without-token.toml' \
            > '${directory}/config.toml'
        |- CMD
        ,
        refreshonly => true,
    }

    systemd::service{ 'gitlab-runner':
        ensure         => 'present',
        content        => template('gitlab_runner/gitlab-runner.service.erb'),
        service_params => {'restart' => 'systemctl restart gitlab-runner'},
        override       => true, #override default unit file for non-root user
        require        => Package['gitlab-runner'],
    }
}
