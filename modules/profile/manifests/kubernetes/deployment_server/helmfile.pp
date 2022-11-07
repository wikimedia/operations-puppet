# SPDX-License-Identifier: Apache-2.0
# Installs helmfile and helmfile-diff, plus
# all the puppet-provided defaults and secrets for each service.
#
class profile::kubernetes::deployment_server::helmfile(
    Hash[String, Hash] $cluster_groups = lookup('kubernetes_cluster_groups'),
    Profile::Kubernetes::User_defaults $user_defaults = lookup('profile::kubernetes::deployment_server::user_defaults'),
    Hash[String, Hash[String, Profile::Kubernetes::Services]] $services = lookup('profile::kubernetes::deployment_server::services', {'default_value' => {}}),
    Hash[String, Any] $services_secrets = lookup('profile::kubernetes::deployment_server_secrets::services', {'default_value' => {}}),
    Hash[String, Any] $default_secrets = lookup('profile::kubernetes::deployment_server_secrets::defaults', {'default_value' => {}}),
    String $helm_user_group = lookup('profile::kubernetes::deployment_server::helm_user_group'),
){
    # Add the global configuration for all deployments.
    require ::profile::kubernetes::deployment_server::global_config

    # Install helmfile and the repository containing helmfile deployments.
    class { 'helmfile': }
    class { 'helmfile::repository':
        repository => 'operations/deployment-charts',
        srcdir     => '/srv/deployment-charts'
    }

    # Install the private values for each deployment.
    $general_private_dir = "${::profile::kubernetes::deployment_server::global_config::general_dir}/private"

    # "service_group" holds a value for each k8s cluster group that we run (main, ml-serve, etc..).
    $services.each |String $service_group, Hash $service_data| {
        $merged_services = deep_merge($service_data, $services_secrets[$service_group])
        $private_dir = "${general_private_dir}/${service_group}_services"

        # Per "service_group" private directory
        file { $private_dir:
            ensure => directory,
            owner  => 'root',
            group  => $helm_user_group,
            mode   => '0750',
        }

        # New-style private directories are one per service, not per cluster too.
        $merged_services.each |String $svcname, Hash $data| {
            $permissions = $data['private_files'] ? {
                undef   => $user_defaults,
                default => $data['private_files']
            }
            $service_dir_ensure = $data['ensure'] ? {
                undef   => directory,
                present => directory,
                default => $data['ensure'],
            }
            file { "${private_dir}/${svcname}":
                ensure  => $service_dir_ensure,
                owner   => $permissions['owner'],
                group   => $permissions['group'],
                mode    => '0750',
                force   => true,
                recurse => true,
            }
        }
        $cluster_groups[$service_group].each |String $environment, Hash $_| {
            $merged_services.map |String $svcname, Hash $data| {
                # Permission and file presence setup
                if $data['private_files'] {
                    $permissions = $user_defaults.merge($data['private_files'])
                } else {
                    $permissions = $user_defaults
                }
                $service_ensure = $data['ensure'] ? {
                    undef   => present,
                    default => $data['ensure'],
                }
                $raw_data = deep_merge($default_secrets[$environment], $data[$environment])
                # write private section only if there is any secret defined.
                unless $raw_data.empty {
                    # Substitute the value of any key in the form <somekey>: secret__<somevalue>
                    # with <somekey>: secret(<somevalue>)
                    # This allows to avoid having to copy/paste certs inside of yaml files directly,
                    # for example.
                    $secret_data = wmflib::inject_secret($raw_data)
                    file { "${private_dir}/${svcname}/${environment}.yaml":
                        ensure  => $service_ensure,
                        owner   => $permissions['owner'],
                        group   => $permissions['group'],
                        mode    => $permissions['mode'],
                        content => to_yaml($secret_data),
                        require => "File[${private_dir}/${svcname}]",
                    }
                }
            }
        } # end clusters
    } # end cluster_directories
}
