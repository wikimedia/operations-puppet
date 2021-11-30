type Ceph::Auth::ClientAuth = Struct[{
    'keydata' => Optional[String[1]],
    'keyring_path' => Optional[Stdlib::AbsolutePath],
    'owner' => Optional[String[1]],
    'group' => Optional[String[1]],
    'mode' => Optional[Stdlib::Filemode],
    'caps' => Ceph::Auth::Caps,
    'import_to_ceph' => Optional[Boolean],
}]
