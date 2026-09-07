class ceph::auth::deploy (
    Hash             $configuration,
    Array[String[1]] $selected_creds,
    Boolean          $manage_keydata = true,
) {
    $configuration.each |String $client_name, Ceph::Auth::ClientAuth $client_auth| {
        if ($client_name in $selected_creds) {
            # A per key value overrides the class default.
            $_manage_keydata = $client_auth['manage_keydata'] ? {
                undef   => $manage_keydata,
                default => $client_auth['manage_keydata'],
            }

            ceph::auth::keyring { $client_name:
                keyring_path   => $client_auth['keyring_path'],
                keydata        => $client_auth['keydata'],
                import_to_ceph => false,
                manage_keydata => $_manage_keydata,
                caps           => $client_auth['caps'],
                owner          => $client_auth['owner'],
                group          => $client_auth['group'],
                mode           => $client_auth['mode'],
            }
        }
    }
}
