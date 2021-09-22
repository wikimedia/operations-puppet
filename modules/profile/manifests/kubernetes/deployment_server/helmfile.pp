# Installs helmfile and helmfile-diff, plus
# all the puppet-provided defaults and secrets for each service.
#
class profile::kubernetes::deployment_server::helmfile(
    Hash[String, String] $clusters = lookup('kubernetes_clusters'),
    Hash[String, Any] $services=lookup('profile::kubernetes::deployment_server::services', {'default_value' => {}}),
    Hash[String, Any] $services_secrets=lookup('profile::kubernetes::deployment_server_secrets::services', {'default_value' => {}}),
    Hash[String, Any] $default_secrets=lookup('profile::kubernetes::deployment_server_secrets::defaults', {'default_value' => {}}),
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
        $merged_services = deep_merge($service_data, $services_secrets[$service_group]).filter|String $svcname, Hash $data| {
            $svcname != 'admin'
        }
        $private_dir = "${general_private_dir}/${service_group}_services"

        file { $private_dir:
            ensure => directory,
            owner  => 'root',
            group  => 'wikidev',
            mode   => '0750',
        }

        # New-style private directories are one per service, not per cluster too.
        $merged_services.each |String $svcname, Hash $data| {
            file { "${private_dir}/${svcname}":
                ensure => directory,
                owner  => $data['owner'],
                group  => $data['group'],
                mode   => '0750',
            }
        }

        $clusters.each |String $environment, String $dc| {
            $merged_services.map |String $svcname, Hash $data| {
                $raw_data = deep_merge($default_secrets[$environment], $data[$environment])
                # write private section only if there is any secret defined.
                unless $raw_data.empty {
                    # Substitute the value of any key in the form <somekey>: secret__<somevalue>
                    # with <somekey>: secret(<somevalue>)
                    # This allows to avoid having to copy/paste certs inside of yaml files directly,
                    # for example.
                    $secret_data = wmflib::inject_secret($raw_data)

                    file { "${private_dir}/${svcname}/${environment}.yaml":
                        owner   => $data['owner'],
                        group   => $data['group'],
                        mode    => $data['mode'],
                        content => ordered_yaml($secret_data),
                        require => "File[${private_dir}/${svcname}]"
                    }
                }
            }
        } # end clusters
    } # end cluster_directories
}
