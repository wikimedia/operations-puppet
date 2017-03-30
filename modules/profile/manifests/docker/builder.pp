# == Class profile::docker::builder
#
# This class sets up a docker builder server, where our base images can be built
# and uploaded to the docker registry.
#
# === Parameters
#
# [*proxy_address*] The http proxy address, set to undef if you don't want to use item
#
# [*proxy_port*] The http proxy port; set to undef if not needed
#
# [*registry*] Address of the docker registry.
#
class profile::docker::builder(
    $proxy_address = hiera('profile::docker::builder::proxy_address', undef),
    $proxy_port = hiera('profile::docker::builder::proxy_port', undef),
    $registry = hiera('docker::registry'),
    ) {

    class { '::docker::baseimages':
        docker_registry => $registry,
        proxy_address   => $proxy_address,
        proxy_port      => $proxy_port,
        distributions   => ['jessie', 'alpine'],
    }

    # TODO: create a repo for base images in prod for this
}
