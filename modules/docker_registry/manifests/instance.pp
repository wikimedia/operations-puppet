# SPDX-License-Identifier: Apache-2.0
#  Puppet define allowing to set up a specific instance of the docker registry. Can be re-used to
# setup more than 1 running on a host
# @param backend. Required. Either "swift" or "s3"
# @param backend_config. Required. A hash having the configuration for the backend. Use the proper YAML straight from
# https://distribution.github.io/distribution/about/configuration/#list-of-configuration-options
# @param redis_config. Required. A hash with the following fields to configure a redis caching service.
#  redis_host. String. The hostname to the Redis host
#  redis_port. Integer. The port redis listen on
#  redis_password. String. Password to connect to redis
#  redis_db. Integer, the Redis database used
# @param registry_shared_secret. String. Only needed if >1 registry behind LB and all instances should have the same. Used to
# prevent against tampering
# @param port. Integer. The port the registry listens on
# @param debug_port. Integer. Optional Debug is where the registry exposes Prometheus metrics. This is the port it listens on
# @param redirect_backend. Boolean. Optional. Allow content redirects from storage backends.
# @param catalog_max_entries. Integer. Optional. Max amout of entries returned by the catalog endpoint.
# @param swift_replication_configuration. String. Optional. The argument to -r parameter of registry_swift_container_replication.sh
# @param swift_replication_key. String. Optional. The argument to -k parameter of registry_swift_container_replication.sh
define docker_registry::instance (
    Docker_registry::Backend $backend,
    Hash $backend_config,
    Docker_registry::Redisconfig $redis_config,
    String  $registry_shared_secret,
    Integer $catalog_maxentries,
    Integer $port=5000,
    Integer $debug_port=5001,
    Boolean $redirect_backend=false,
    Optional[Pattern[/\/\/[a-zA-Z_]{3,}\/[a-zA-Z_]{3,}\/AUTH_[a-zA-Z_]+\/[a-z_]{3,}/]] $swift_replication_configuration=undef,
    Optional[String] $swift_replication_key=undef,
){
    if $backend == 'swift' {
        # These are repopulated here for creating the account file and Exec Puppet resources
        $swift_url = $backend_config['authurl']
        $swift_user = $backend_config['username']
        $swift_password = $backend_config['password']
        $swift_container = $backend_config['container']

        $account_file = "/etc/swift/account_${swift_user}.env"
        file { $account_file:
            owner   => 'root',
            group   => 'docker-registry',
            mode    => '0440',
            content => "export ST_AUTH=${swift_url}\nexport ST_USER=${swift_user}\nexport ST_KEY=${swift_password}\n"
        }
        exec { 'create_swift_container_replication':
            command => "/usr/local/bin/registry_swift_container_replication.sh -x -a ${account_file} \
                        -r ${swift_replication_configuration} \
                        -k ${swift_replication_key} \
                        -c ${swift_container}",
            unless  => "/usr/local/bin/registry_swift_container_replication.sh -t -a ${account_file} \
                        -c ${swift_container}",
            cwd     => '/tmp',
            path    => '/bin:/sbin:/usr/bin:/usr/sbin',
            user    => 'docker-registry'
        }
        $storage_config = {
            'storage' => {
                'swift'    => $backend_config,
                'redirect' => {
                    'disable' => !$redirect_backend,
                }
            }
        }
    } elsif $backend == 's3' {
        $storage_config = {
            'storage' => {
                's3'       => $backend_config,
                'redirect' => {
                    'disable' => !$redirect_backend,
                }
            }
        }
    } else {
        # This should never happen
        fail('Unsupported backend')
    }
    # Read the basic configuration from a YAML file, merge in the parameters, spit it out as YAML file
    # Why? Cause carrying the configuration in a Puppet hash, while feasible is less readable. And messing with YAML in
    # ERB is most definitely not fun
    $module_path = get_module_path($module_name)
    $base_config = loadyaml("${module_path}/files/base-config.yaml")
    $overrides = {
        'http'    => {
            'addr'   => ":${port}",
            'secret' => $registry_shared_secret,
            'debug'  => {
                'addr' => ":${debug_port}",
            }
        },
        'redis'   => $redis_config,
        'catalog' => {
            'maxentries' => $catalog_maxentries,
        },
        'health'  => {
            'tcp' => [{ 'addr' => $redis_config['addr']}],
        }
    }
    $config = deep_merge($base_config, $overrides, $storage_config)

    file { "/etc/docker/registry/config-${title}.yml":
        content => to_yaml($config),
        owner   => 'docker-registry',
        group   => 'docker-registry',
        mode    => '0440',
        notify  => Service['docker-registry'],
    }

    systemd::service { "docker-registry-${title}":
        ensure         => 'present',
        content        =>  systemd_template('registry'),
        restart        => true,
        team           => 'ServiceOps',
        service_params => {
            enable  => true,
        },
    }
}
