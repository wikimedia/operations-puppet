class profile::codesearch (
    Stdlib::Unixpath $base_dir = lookup('profile::codesearch::base_dir'),
    Hash[String, Integer] $ports = lookup('profile::codesearch::ports'),
) {

    class { '::codesearch':
        base_dir => $base_dir,
        ports    => $ports,
    }
}
