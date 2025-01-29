# SPDX-License-Identifier: Apache-2.0
# @summary Class that sets up and configures kubectl
# @param version Optional version of kubectl to install, if not set, all versions we're running clusters on are installed
class k8s::client (
    Optional[K8s::KubernetesVersion] $version,
) {
    if $version != undef {
        k8s::package { 'kubectl':
            package => 'client',
            version => $version,
        }
    } else {
        # Install kubectl for all k8s versions we're running
        k8s::fetch_clusters(false).map | $_, K8s::ClusterConfig $config | {
            $config['version']
        }.unique.each |$version| {
            k8s::package { "kubectl-${version}":
                package => 'client',
                version => $version,
            }
        }
    }
}
