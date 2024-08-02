# SPDX-License-Identifier: Apache-2.0
# == Class: profile::benthos
#
# Deploy self-contained Benthos instances
# and configurations, together with base package etc..
#
class profile::benthos(
    Wmflib::Ensure $ensure = lookup('profile::benthos::ensure', { 'default_value' => present }),
    Hash[String, Any] $instances = lookup('profile::benthos::instances'),
    Boolean $use_geoip = lookup('profile::benthos::use_geoip', { 'default_value' => false} ),
) {
    class { 'benthos':
        ensure => $ensure,
    }

    if $use_geoip {
        class { 'geoip': }
    }

    $instances.each | $instance, $instance_config | {
        if has_key($instance_config, 'kafka') {
            $kafka_cluster_name = sprintf('%s-%s', $instance_config['kafka']['cluster'], $instance_config['kafka']['site'])
            $kafka = kafka_config($kafka_cluster_name)
            # Setting up base environment variables
            $kafka_env_variables = {
                kafka_brokers => $kafka['brokers']['ssl_string'],
                kafka_topics  => join($instance_config['kafka']['topics'], ','),
            }
        } else {
            $kafka_env_variables = {}
        }

        $base_env_variables = {
            port => $instance_config['port'],
        }

        $custom_env_variables = $instance_config['env_variables'] ? {
            undef   => {},
            default => $instance_config['env_variables'],
        }

        $instance_ensure = $ensure == 'absent' ? {
            true    => 'absent',
            default => $instance_config['ensure'],
        }

        benthos::instance { $instance:
            ensure        => $instance_ensure,
            env_variables => $base_env_variables + $kafka_env_variables + $custom_env_variables,
            config_source => "profile/benthos/instances/${instance}.yaml",
            port          => $instance_config['port'],
        }
    }
}
