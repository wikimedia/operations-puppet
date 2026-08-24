# SPDX-License-Identifier: Apache-2.0
# @summary
#   Install and configure containerd for kubernetes
class profile::containerd (
    Wmflib::Ensure $ensure = lookup('profile::containerd::ensure', { 'default_value' => present }),
    String $kubernetes_cluster_name = lookup('profile::kubernetes::cluster_name'),
    Optional[String] $registry_username = lookup('profile::containerd::registry_username', { 'default_value' => 'kubernetes' }),
    Optional[String] $registry_password = lookup('profile::containerd::registry_password', { 'default_value' => undef }),
    Wmflib::Ensure $dragonfly_ensure = lookup('profile::dragonfly::dfdaemon::ensure', { 'default_value' => absent }),
    Boolean $gvisor_enabled = lookup('profile::containerd::gvisor_enabled', { 'default_value' => false }),
) {
    $k8s_config = k8s::fetch_cluster_config($kubernetes_cluster_name)
    ensure_packages(['crictl'])

    # Check if dragonfly::dfdaemon is configured for this host
    $dragonfly_enabled = $dragonfly_ensure ? {
        'absent'  => false,
        default   => true,
    }

    # gVisor configuration profiles.
    # default - typically how we should run most workloads
    # debug - for debugging stuff when something fails, enables strace and debug logging
    # throughput - for workloads that need high throughput, disables sandbox networking
    # performance - for workloads that need high throughput and low latency, disables sandbox networking
    #          and enables exclusive file access
    $runsc_config = $gvisor_enabled ? {
        true  => {
            'default' => {
                'platform' => 'systrap',
                'debug' => 'false',
                'strace' => 'false',
                'network' => 'sandbox',
                'gso' => 'true',
            },
            'debug' => {
                'platform' => 'systrap',
                'debug' => 'true',
                'strace' => 'true',
                'network' => 'sandbox',
                'gso' => 'true',
            },
            'throughput' => {
                'platform' => 'systrap',
                'debug' => 'false',
                'strace' => 'false',
                'network' => 'host',
            },
            'performance' => {
                'platform' => 'systrap',
                'debug' => 'false',
                'strace' => 'false',
                'network' => 'host',
                'file-access' => 'exclusive',
            },
        },
        false => {},
    }

    class { 'containerd::configuration':
        ensure            => $ensure,
        sandbox_image     => $k8s_config['infra_pod'],
        dragonfly_enabled => $dragonfly_enabled,
        registry_username => $registry_username,
        registry_password => $registry_password,
        runsc_config      => $runsc_config,
    }

    # Configure gVisor if enabled.
    $gvisor_ensure = stdlib::ensure($ensure and $gvisor_enabled)

    apt::package_from_component { 'gvisor':
        ensure    => $gvisor_ensure,
        component => 'thirdparty/gvisor',
        packages  => ['runsc'],
    }

    class { 'containerd':
        ensure => $ensure,
    }

    class { 'containerd::nerdctl':
        ensure => $ensure,
    }
}
