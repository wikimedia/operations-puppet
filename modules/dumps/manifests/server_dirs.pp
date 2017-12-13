class dumps::server_dirs(
    $datadir         = undef,
    $xmldumpsdir     = undef,
    $miscdatasetsdir = undef,
    $user            = undef,
    $group           = undef,
) {
    # top level directories for various dumps/datasets
    file { [$datadir, $xmldumpsdir, $miscdatasetsdir]:
        ensure => 'directory',
        mode   => '0755',
        owner  => $user,
        group  => $group,
    }
}
