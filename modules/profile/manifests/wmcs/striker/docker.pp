# SPDX-License-Identifier: Apache-2.0
# @summary Run Striker containers using Docker
# @param instances List of Striker instances to run on this host.
# @param common_env Key-value hash of env variables to pass to all instances.
# @param common_secret_env Key-value hash of env variables to pass to all
#   instances. Useful for setting configuration values that for one reason or
#   another cannot be provided via `common_env` (probably because the values
#   need to be kept out of public hiera files).
# @param instances_secret_env Key-value hash of env variables per instance to
#   pass to Striker instances. Useful for setting per-instance envvars that
#   can't be made public for one reason or another.
# @param cache_hosts List of hosts to trust XFF data from.
class profile::wmcs::striker::docker(
    Hash[String[1], Profile::Wmcs::Striker::Instance] $instances            = lookup('profile::wmcs::striker::docker::instances'),
    Hash[String[1], Any]                              $common_env           = lookup('profile::wmcs::striker::docker::common_env'),
    Hash[String[1], Any]                              $common_secret_env    = lookup('profile::wmcs::striker::docker::common_secret_env', { 'default_value' => {} } ),
    Hash[String[1], Hash[String[1], Any]]             $instances_secret_env = lookup('profile::wmcs::striker::docker::instances_secret_env', { 'default_value' => {} } ),
    Array[Stdlib::IP::Address]                        $cache_hosts          = lookup('cache_hosts'),
) {
    require ::profile::docker::engine
    require ::profile::docker::ferm

    $trusted_proxies_env = { 'TRUSTED_PROXY_LIST' => $cache_hosts.join(',') }
    $shared_env = $trusted_proxies_env + $common_env + $common_secret_env

    $instances.each |String[1] $name, Profile::Wmcs::Striker::Instance $instance| {
        $instance_env = $instance['env'] + pick($instances_secret_env[$name], {})
        service::docker { $name:
            namespace    => 'wikimedia',
            image_name   => 'labs-striker',
            version      => $instance['version'],
            port         => $instance['port'],
            override_cmd => "127.0.0.1:${instance['port']}",
            environment  => $shared_env + $instance_env,
            host_network => true,
        }
    }
}
