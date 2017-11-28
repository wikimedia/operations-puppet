class profile::docker::flannel(
    # Docker version in use. The systemd override is specific
    # to the version in use.
    $docker_version = hiera('profile::flannel::docker_version'),
) {
    # TODO: convert to systemd::service
    base::service_unit { 'docker':
        ensure           => present,
        systemd_override => init_template("docker/flannel/docker_${docker_version}", 'systemd_override'),
        # Restarts must always be manual, since restart
        # destroy all running containers. Fuck you, Docker.
        refresh          => false,
    }
}
