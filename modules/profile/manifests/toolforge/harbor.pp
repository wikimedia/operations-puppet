class profile::toolforge::harbor (
) {
    require profile::wmcs::kubeadm::client
    acme_chief::cert { 'toolforge': }
}
