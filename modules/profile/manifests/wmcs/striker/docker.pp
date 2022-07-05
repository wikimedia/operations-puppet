# === Class profile::wmcs::striker::docker
#
# Run Striker container using Docker
#
# === Parameters
# [*port*]
#   Port that should be exposed for ingress to app
# [*version*]
#   Container tag to deploy.
# [*env*]
#   Key-value hash pf env variables to pass to the container.
# [*secret_env*]
#   Additional env variables to pass to the container. Useful for setting
#   configuration values that for one reason or another cannot be provided via
#   `env` (probably because the values need to be kept out of public hiera
#   files).
#
# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::striker::docker(
    Stdlib::Port::User $port = lookup('profile::wmcs::striker::docker::port'),
    String $version          = lookup('profile::wmcs::striker::docker::version'),
    Hash $env                = lookup('profile::wmcs::striker::docker::env'),
    Hash $secret_env         = lookup('profile::wmcs::striker::docker::secret_env', { 'default_value' => {} } ),
) {
    require ::profile::docker::engine
    require ::profile::docker::ferm
    service::docker { 'striker':
        namespace    => 'wikimedia',
        image_name   => 'labs-striker',
        version      => $version,
        port         => $port,
        environment  => deep_merge($env, $secret_env),
        host_network => true,
    }
}
