# === Define service::docker
#
# Allows pulling a docker image from our registry, and running it.
#
# This is basically a shim to be able to run via puppet the containers we
# created for use with the new service pipeline in mind.
#
# === Parameters
#
# [*image_name*]
#   Name of the Docker image.  Default: $title
#
# [*version*] The docker image tag
#
# [*namespace*] The namespace of the image on the registry, if any
#
#   The fully qualified image name (FQIN) of the image
#   will be docker-registry.wikimedia.org/${namespace}/${image_name}
#   or docker-registry.wikimedia.org/${image_name} if the namespace
#   is undefined.
#
#
# [*port*] the IP port the service runs on, and that will be exposed
#   on. For now, the container port and the host port must be the same
#   and cannot be specified separately.
#
# [*override_cmd*] The command to run if different from what defined
#   in the images's CMD stanza.
#
# [*environment*] k-v hash of env variables to pass to the container
#
# [*volume*] Boolean. default false.
#   Whether a volume should be reserved for the configuration file. This is here
#   just to bypass a 64KB limitation of horizon, so don't use it for other
#   reasons. If set to true, then instead of bind mounting /etc/${title} from
#   the host, a named docker volume $title will be mounted. The entire lifecycle
#   management of that docker volume is left up to the user of the volume. So
#   precreate it and prepopulate it please
#
# [*host_network*] Boolean. default false.
#   Bind the container to the host's network rather than the default bridge
#   nework. From a networking point of view, this provides the same level of
#   iolation as if the container's main process was running directly on the
#   host. Note: $port is ignored when running in host network mode. Ports
#   opened within the container will be opened directly on the host without
#   a NAT translation being involved.
#
# [*runtime*] String. default undef. If set, specifies the container runtime.
#
define service::docker(
    Stdlib::Port::User $port,
    String $version,
    Wmflib::Ensure $ensure = present,
    Optional[String] $namespace = undef,
    Hash $config = {},
    String $override_cmd = '',
    Hash $environment = {},
    String $image_name = $title,
    Boolean $volume = false,
    Boolean $host_network = false,
    Optional[String] $runtime = undef,
) {
    # Our docker registry is *not* configurable here.
    $registry = 'docker-registry.wikimedia.org'
    $image_full_name = $namespace ? {
        undef => "${registry}/${image_name}",
        default => "${registry}/${namespace}/${image_name}"
    }

    $fqin = "${image_full_name}:${version}"

    # The config file will be mounted as a read-only volume inside the container
    if !defined(File["/etc/${title}"]) {
        file { "/etc/${title}":
            ensure => stdlib::ensure($ensure, 'directory'),
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
    }

    if $volume == false {
        file { "/etc/${title}/config.yaml":
            ensure  => $ensure,
            content => to_yaml($config),
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            notify  => Service[$title],
        }
    }

    file { "/etc/${title}/env":
        ensure    => $ensure,
        content   => ($environment.map |$k, $v| { "${k}=${v}" } + ['']).join("\n"),
        owner     => 'root',
        group     => 'root',
        mode      => '0440',
        notify    => Service[$title],
        show_diff => false,
    }

    # Make sure the image has been pulled before starting the service
    # docker pull does not support a --dry-run. Therefore the actual pull is
    # done via the `unless` command.
    exec { "docker pull of ${fqin} for ${title}":
        command => '/usr/bin/true',
        unless  => "/usr/bin/docker pull '${fqin}' | grep -q 'up to date'",
        notify  => Service[$title],
    }

    systemd::service { $title:
        ensure  => $ensure,
        content => template('service/docker-service-shim.erb'),
        restart => true,
    }
}
