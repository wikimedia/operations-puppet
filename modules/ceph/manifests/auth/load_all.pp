class ceph::auth::load_all (
    Hash $configuration,
) {
    $configuration.each |String $client_name, Ceph::Auth::ClientAuth $client_auth| {
        if ($client_auth['keydata'] == undef) {
            notify{"No keydata found for key ${client_name}, skipping.": }

        } else {
            $keyring_path = pick($client_auth['keyring_path'], "/etc/ceph/ceph.client.${client_name}.keyring")
            ceph::auth::keyring { $client_name:
                keyring_path   => $keyring_path,
                keydata        => $client_auth['keydata'],
                import_to_ceph => true,
                caps           => $client_auth['caps'],
            }
        }
    }
}
