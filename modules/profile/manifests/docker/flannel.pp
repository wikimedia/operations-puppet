class profile::docker::flannel(
    # Docker version in use. The systemd override is specific
    # to the version in use.
    $docker_version = hiera('profile::flannel::docker_version'),
) {
    base::service_unit { 'docker':
        ensure           => present,
        systemd          => false,
        systemd_override => true,
        # Restarts must always be manual, since restart
        # destroy all running containers. Fuck you, Docker.
        refresh          => false,
        template_name    => "docker/flannel/docker_${docker_version}",
    }
}
