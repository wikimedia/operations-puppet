# SPDX-License-Identifier: Apache-2.0
# == Class: profile::benthos
#
# Deploy self-contained Benthos instances
# and configurations, together with base package etc..
#
class profile::benthos(
    Hash[String, Any] $instances = lookup('profile::benthos::instances'),
    Boolean $use_geoip = lookup('profile::benthos::use_geoip', { 'default_value' => false} ),
) {
    class { 'benthos': }

    if $use_geoip {
        class { 'geoip': }
    }

    $instances.each | $instance, $instance_config | {
        $kafka = kafka_config($instance_config['kafka']['cluster'], $instance_config['kafka']['site'])
        # Setting up base environment variables
        $base_env_variables = {
            port          => $instance_config['port'],
            kafka_brokers => $kafka['brokers']['ssl_string'],
            kafka_topics  => join($instance_config['kafka']['topics'], ',')
        }
        $custom_env_variables = $instance_config['env_variables'] ? {
            undef   => {},
            default => $instance_config['env_variables'],
        }
        benthos::instance { $instance:
            ensure        => $instance_config['ensure'],
            env_variables => $base_env_variables + $custom_env_variables,
            config        => template("profile/benthos/instances/${instance}.yaml.erb"),
            port          => $instance_config['port'],
        }
    }
}
