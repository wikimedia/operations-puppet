# SPDX-License-Identifier: Apache-2.0
#
# Create a capi worker node for OpenStack Magnum.
#
# Installs k3s, helm, and capi
class profile::openstack::capi(
  Stdlib::HTTPSUrl $cluster_ctl_url = lookup('profile::openstack::capi::cluster_ctl_url', {'default_value' => 'https://object.eqiad1.wikimediacloud.org/swift/v1/AUTH_c2c23ceb46404a62a80492b07dac4685'}),
  Stdlib::Host     $docker_repo_base = lookup('profile::openstack::capi::docker_repo_base', {'default_value' => 'docker-registry.wmcloud.org'}),
  String           $cluster_api_version = lookup('profile::openstack::capi::cluster_api_version', {'default_value' => 'v1.13.2'}),
  String           $cluster_api_provider_openstack_version = lookup('profile::openstack::capi::cluster_api_provider_openstack_version', {'default_value' => 'v0.14.4'}),
) {
    class { '::k3s':
        k3s_args => '--disable traefik',
    }

    class { '::helm':
        helm_user_group => root,
        repositories    => {
            'magnum' => 'https://object.eqiad1.wikimediacloud.org/swift/v1/AUTH_c2c23ceb46404a62a80492b07dac4685/helmcharts',
        },
    }

    class { '::openstack::clusterapi::service':
        cluster_ctl_url                        => $cluster_ctl_url,
        docker_repo_base                       => $docker_repo_base,
        cluster_api_version                    => $cluster_api_version,
        cluster_api_provider_openstack_version => $cluster_api_provider_openstack_version,
        require                                => [Exec['install k3s'], Class['helm']],
    }
}
