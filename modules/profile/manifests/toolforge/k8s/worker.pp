class profile::toolforge::k8s::worker () {
    class { '::profile::wmcs::kubeadm::worker': }
    contain '::profile::wmcs::kubeadm::worker'

    # The Cloud VPS network test suite relies on logging in to these hosts
    # as they do not use floating IPs but do have (dumps) NFS shares mounted.
    # Previously that worked when the network test service account was a part
    # of tools.admin, but that was removed in
    # https://phabricator.wikimedia.org/T393775. Instead we provision an
    # explicit rule for that user here - logging in as an unprivileged user
    # should be relatively safe, and this is still better than letting any
    # Toolforge users log in.
    security::access::config { 'network-tests':
        content  => "+ : srv-networktests : ALL\n",
        priority => 60,
    }
}
