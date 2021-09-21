class profile::toolforge::harbor (
) {
    require profile::wmcs::kubeadm::client

    ensure_packages(['postgresql-client', 'redis-tools'])
    acme_chief::cert { 'toolforge': }
}
