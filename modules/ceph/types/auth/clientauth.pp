type Ceph::Auth::ClientAuth = Struct[{
    'keydata' => String[1],
    'keyring_path' => Stdlib::AbsolutePath,
    'caps' => Ceph::Auth::Caps,
}]
