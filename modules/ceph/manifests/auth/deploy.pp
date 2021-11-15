class ceph::auth::deploy (
    Hash             $configuration,
    Array[String[1]] $selected_creds,
) {
    $configuration.each |String $client_name, Ceph::Auth::ClientAuth $client_auth| {
        if ($client_name in $selected_creds) {
            ceph::auth::keyring { $client_name:
                keyring_path   => $client_auth['keyring_path'],
                keydata        => $client_auth['keydata'],
                import_to_ceph => false,
                caps           => $client_auth['caps'],
                owner          => $client_auth['owner'],
                group          => $client_auth['group'],
                mode           => $client_auth['mode'],
            }
        }
    }
}
