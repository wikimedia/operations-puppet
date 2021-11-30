function ceph::auth::get_keyring_path (
    String[1]                      $client_name,
    Optional[Stdlib::AbsolutePath] $keyring_path = undef,
) >> Stdlib::Unixpath {
    $keyring_path ? {
        undef   => "/etc/ceph/ceph.${client_name}.keyring",
        default => $keyring_path,
    }
}
