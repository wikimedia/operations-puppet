type Ceph::Auth::ClientAuth = Struct[{
    'keydata' => Optional[String[1]],
    'keyring_path' => Optional[Stdlib::AbsolutePath],
    'caps' => Ceph::Auth::Caps,
}]
