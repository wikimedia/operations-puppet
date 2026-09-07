class ceph::auth::load_all (
    Ceph::Auth::Conf $configuration,
    Boolean          $manage_keydata = true,
) {
    $configuration.each |String $client_name, Ceph::Auth::ClientAuth $client_auth| {
        if ($client_auth['keydata'] == undef) {
            notify{"No keydata found for key ${client_name}, skipping.": }
        } elsif ($client_auth['caps'] == undef) {
            notify{"No caps found for key ${client_name}, skipping.": }
        } else {
            if ($client_auth['import_to_ceph'] == undef) {
                # the default value
                $import_to_ceph = true
            } else {
                $import_to_ceph = $client_auth['import_to_ceph']
            }

            # A per key value overrides the class default.
            $_manage_keydata = $client_auth['manage_keydata'] ? {
                undef   => $manage_keydata,
                default => $client_auth['manage_keydata'],
            }

            ceph::auth::keyring { $client_name:
                keyring_path   => $client_auth['keyring_path'],
                keydata        => $client_auth['keydata'],
                import_to_ceph => $import_to_ceph,
                manage_keydata => $_manage_keydata,
                caps           => $client_auth['caps'],
            }
        }
    }
}
