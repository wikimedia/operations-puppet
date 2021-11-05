class ceph::auth::load_all (
    Hash $configuration,
) {
    $configuration.each |String $client_name, Ceph::Auth::ClientAuth $client_auth| {
        $keyring_path = pick($client_auth['keyring_path'], "/etc/cept/ceph.client.${client_name}.keyring")
        ceph::auth::keyring { $client_name:
            keyring_path   => $keyring_path,
            keydata        => $client_auth['keydata'],
            import_to_ceph => true,
            caps           => $client_auth['caps'],
        }
    }
}
