define ceph::auth::keyring (
    String[1]                      $keydata,
    Ceph::Auth::Caps               $caps,
    Optional[Stdlib::AbsolutePath] $keyring_path   = undef,
    Boolean                        $import_to_ceph = false,
    Boolean                        $manage_keydata = true,
    String[1]                      $cluster        = 'ceph',
    String[1]                      $ensure         = 'present',
    String[1]                      $group          = 'ceph',
    String[1]                      $mode           = '0600',
    String[1]                      $owner          = 'ceph',
) {
    # Provides the script that compares this keyring against the cluster.
    include ceph::auth::verify

    $client_name = $name ? {
        /\./    => $name,
        default => "client.${name}",
    }
    $_keyring_path = ceph::auth::get_keyring_path($client_name, $keyring_path)

    ensure_packages('ceph-common')

    # make sure the path hosting the file exists. This method should allow for
    # callers to declare a File resource for the parent dir elsewhere in the code
    wmflib::dir::mkdir_p($_keyring_path.dirname)

    file { $_keyring_path:
        ensure    => present,
        mode      => $mode,
        owner     => $owner,
        group     => $group,
        content   => epp('ceph/auth/keyring.epp', {
            client_name => $client_name,
            keydata     => $keydata,
            caps        => $caps
        }),
        # If manage_keydata is false, Puppet creates the keyring file only if it is
        # absent. Puppet does not replace the key material. Use this to rotate keys.
        replace   => $manage_keydata,
        show_diff => false,
        require   => Package['ceph-common'],
    }

    if $import_to_ceph and $manage_keydata {
        $caps_opts = join(
            $caps.map |$cap_name, $cap_value| { "${cap_name} '${cap_value}'" },
            ' ',
        )
        exec { "ceph-auth-load-key-${name}":
            # This command creates the auth if it is absent. It also updates the capabilities.
            command => "/usr/bin/ceph --in-file '${_keyring_path}' auth import",
            # This command compares only the capabilities. It does not compare the key
            # material, so a change to keydata alone does not converge. See T399594.
            unless  => "/usr/bin/ceph --in-file '${_keyring_path}' auth get-or-create-key '${client_name}' ${caps_opts}",
            require =>  [Package['ceph-common'], File[$_keyring_path]],
        }
    }
}
