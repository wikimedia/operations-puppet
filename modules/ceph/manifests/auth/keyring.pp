define ceph::auth::keyring (
    Stdlib::AbsolutePath $keyring_path,
    String[1]            $keydata,
    Ceph::Auth::Caps     $caps,
    Boolean              $import_to_ceph = false,
    String[1]            $cluster        = 'ceph',
    String[1]            $ensure         = 'present',
    String[1]            $group          = 'ceph',
    String[1]            $mode           = '0600',
    String[1]            $owner          = 'ceph',
) {
    $client_name = "client.${name}"

    ensure_packages('ceph-common')

    file { $keyring_path:
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
            command => "/usr/bin/ceph --in-file '${keyring_path}' auth import",
            # the following command either creates the auth, or if it's there already, it checks if it has the
            # same key data and capabilities and fails if there's any difference.
            unless  => "/usr/bin/ceph --in-file '${keyring_path}' auth get-or-create-key '${client_name}' ${caps_opts}",
            require =>  [Package['ceph-common'], File[$keyring_path]],
        }
    }
}
