define ceph::auth::keyring (
    String[1]                      $keydata,
    Ceph::Auth::Caps               $caps,
    Optional[Stdlib::AbsolutePath] $keyring_path   = undef,
    Boolean                        $import_to_ceph = false,
    String[1]                      $cluster        = 'ceph',
    String[1]                      $ensure         = 'present',
    String[1]                      $group          = 'ceph',
    String[1]                      $mode           = '0600',
    String[1]                      $owner          = 'ceph',
) {
    $client_name = $name ? {
        /\./    => $name,
        default => "client.${name}",
    }
    $_keyring_path = ceph::auth::get_keyring_path($client_name, $keyring_path)

    ensure_packages('ceph-common')

    # make sure the path hosting the file exists. This method should allow for
    # callers to declare a File resource for the parent dir elsewhere in the code
    wmflib::dir::mkdir_p($_keyring_path.dirname, {
        owner     => $owner,
        group     => $group,
    })

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
        show_diff => false,
        require   => Package['ceph-common'],
    }

    if $import_to_ceph {
        $caps_opts = join(
            $caps.map |$cap_name, $cap_value| { "${cap_name} '${cap_value}'" },
            ' ',
        )
        exec { "ceph-auth-load-key-${name}":
            # the following command creates new keys if they are not there, or updates them with the
            # new capabilities.
            command => "/usr/bin/ceph --in-file '${_keyring_path}' auth import",
            # the following command either creates the auth, or if it's there already, it checks if it has the
            # same key data and capabilities and fails if there's any difference.
            unless  => "/usr/bin/ceph --in-file '${_keyring_path}' auth get-or-create-key '${client_name}' ${caps_opts}",
            require =>  [Package['ceph-common'], File[$_keyring_path]],
        }
    }
}
