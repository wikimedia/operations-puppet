# SPDX-License-Identifier: Apache-2.0
# == Class profile::calico::kubernetes
#
# Installs calico for use in a kubernetes cluster.
# This follows https://docs.projectcalico.org/getting-started/kubernetes/#manual-installation
# It also optionally deploys Istio CNI configurations, since (Istio) upstream
# suggests to use a chained config with Calico.

class profile::calico::kubernetes (
    Calico::CalicoVersion $calico_version = lookup('profile::calico::kubernetes::calico_version'),
    String $calico_cni_username = lookup('profile::calico::kubernetes::calico_cni::username', { default_value => 'calico-cni' }),
    String $calicoctl_username = lookup('profile::calico::kubernetes::calicoctl::username', { default_value => 'calicoctl' }),
    Stdlib::Host $master_fqdn = lookup('profile::kubernetes::master_fqdn'),
    Array[Stdlib::Host] $bgp_peers = lookup('profile::calico::kubernetes::bgp_peers'),
    Hash $calico_cni_config = lookup('profile::calico::kubernetes::cni_config'),
    String $istio_cni_username = lookup('profile::calico::kubernetes::istio_cni_username', { default_value => 'istio-cni' }),
    String $istio_cni_version = lookup('profile::calico::kubernetes::istio_cni_version', { default_value => '1.15' }),
    # It is expected that there is a second intermediate suffixed with _front_proxy to be used
    # to configure the aggregation layer. So by setting "wikikube" here you are required to add
    # the intermediates "wikikube" and "wikikube_front_proxy".
    #
    # FIXME: This should be something like "cluster group/name" while retaining the discrimination
    #        between production and staging as we don't want to share the same intermediate across
    #        that boundary.
    # FIXME: This is *not* optional for k8s versions > 1.16
    Optional[Cfssl::Ca_name] $pki_intermediate = lookup('profile::kubernetes::pki::intermediate', { default_value => undef }),
    # 952200 seconds is the default from cfssl::cert:
    # the default https checks go warning after 10 full days i.e. anywhere
    # from 864000 to 950399 seconds before the certificate expires.  As such set this to
    # 11 days + 30 minutes to capture the puppet run schedule.
    Integer[1800] $pki_renew_seconds = lookup('profile::kubernetes::pki::renew_seconds', { default_value => 952200 })
) {
    $calicoctl_client_cert = profile::pki::get_cert($pki_intermediate, $calicoctl_username, {
        'renew_seconds'  => $pki_renew_seconds,
        'outdir'         => '/etc/kubernetes/pki',
    })
    class { 'calico':
        master_fqdn        => $master_fqdn,
        calicoctl_username => $calicoctl_username,
        auth_cert          => $calicoctl_client_cert,
        calico_version     => $calico_version,
    }

    k8s::kubelet::cni { 'calico':
        priority => 10,
        config   => $calico_cni_config,
    }

    $calico_cni_client_cert = profile::pki::get_cert($pki_intermediate, $calico_cni_username, {
        'renew_seconds'  => $pki_renew_seconds,
        'outdir'         => '/etc/kubernetes/pki',
    })
    k8s::kubeconfig { '/etc/cni/net.d/calico-kubeconfig':
        master_host => $master_fqdn,
        username    => $calico_cni_username,
        auth_cert   => $calico_cni_client_cert,
        require     => File['/etc/cni/net.d'],
    }

    # Install istio-cni package and provide a kubeconfig for it in case
    # a cni plugin of type "istio-cni" is configured.
    $ensure_istio_cni = pick($calico_cni_config['plugins'], []).filter | $plugin | {
        $plugin['type'] == 'istio-cni'
    }.empty.bool2str('absent', 'present')
    $istio_cni_version_safe = regsubst($istio_cni_version, '\.', '', 'G')
    apt::package_from_component { "istio${istio_cni_version_safe}":
        component => "component/istio${istio_cni_version_safe}",
        packages  => { 'istio-cni' => $ensure_istio_cni },
    }
    $istio_cni = profile::pki::get_cert($pki_intermediate, $istio_cni_username, {
        ensure           => $ensure_istio_cni,
        'renew_seconds'  => $pki_renew_seconds,
        'outdir'         => '/etc/kubernetes/pki',
    })
    k8s::kubeconfig { '/etc/cni/net.d/istio-kubeconfig':
        ensure      => $ensure_istio_cni,
        master_host => $master_fqdn,
        username    => $istio_cni_username,
        auth_cert   => $istio_cni,
        require     => File['/etc/cni/net.d'],
    }

    # TODO: We need to configure BGP peers in calico datastore (helm chart) as well.
    $bgp_peers_ferm = join($bgp_peers, ' ')
    ferm::service { 'calico-bird':
        proto  => 'tcp',
        port   => '179', # BGP
        srange => "(@resolve((${bgp_peers_ferm})) @resolve((${bgp_peers_ferm}), AAAA))",
    }
    # All nodes need to talk to typha and it runs as hostNetwork pod
    # TODO: If and when we move to a layered BGP hierarchy, revisit the use of
    # $bgp_peers.
    ferm::service { 'calico-typha':
        proto  => 'tcp',
        port   => '5473',
        srange => "(@resolve((${bgp_peers_ferm})) @resolve((${bgp_peers_ferm}), AAAA))",
    }
}
