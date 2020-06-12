class profile::wmcs::paws::k8s::haproxy (
) {
    $cert_name = 'paws'
    acme_chief::cert { $cert_name:
        puppet_rsc => Service['haproxy'],
    }

    # TODO: in T255249 we will try to generated the bundled pem file automatically. For now, this
    # has to be done in the server by hand.

    class { '::profile::wmcs::kubeadm::haproxy':
        ingress_bind_tls_port => '443',
        ingress_tls_pem_file  => "/etc/acmecerts/${cert_name}.pem",
    }
    contain '::profile::wmcs::kubeadm::haproxy'
}
