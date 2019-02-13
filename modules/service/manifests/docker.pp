# === Define service::docker
#
# Allows pulling a docker image from our registry, and running it.
#
# This is basically a shim to be able to run via puppet the containers we
# created for use with the new service pipeline in mind.
#
# === Parameters
#
# [*port*] the IP port the service runs on, and that will be exposed
#   on. For now, the port needs to be the same.
#
# [*version*] The docker image tag
#
# [*namespace*] The namespace of the image on the registry, if any
#
# [*override_cmd*] The command to run if different from what defined
#   in the images's CMD stanza.
#
# [*environment*] k-v hash of env variables to pass to the container
#
define service::docker(
    Wmflib::UserIpPort $port,
    String $version,
    Wmflib::Ensure $ensure = present,
    Optional[String] $namespace = undef,
    Hash $config = {},
    String $override_cmd = '',
    Hash $environment = {},
) {
    # Our docker registry is *not* configurable here.
    $registry = 'docker-registry.wikimedia.org'
    $image_full_name = $namespace ? {
        undef => "${registry}/${title}",
        default => "${registry}/${namespace}/${title}"
    }

    if $version == 'latest' {
        fail('Meta tags like "latest" are not allowed')
    }
    # The config file will be mounted as a read-only volume inside the container
    file { "/etc/${title}":
        ensure => ensure_directory($ensure),
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { "/etc/${title}/config.yaml":
        ensure  => $ensure,
        content => ordered_yaml($config),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    # Make sure we have at least one version installed. It's strongly
    # recommended that you properly configure this.
    exec { "docker pull of ${title}:${version}":
        command => "/usr/bin/docker pull '${image_full_name}:${version}'",
        unless  => "/usr/bin/docker images | fgrep '${image_full_name}' | fgrep -q '${version}'",
        notify  => Systemd::Service[$title],
    }

    systemd::service { $title:
        ensure  => $ensure,
        content => template('service/docker-service-shim.erb'),
        restart => true,
    }
}
