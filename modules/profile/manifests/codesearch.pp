class profile::codesearch (
    Stdlib::Unixpath $base_dir = lookup('profile::codesearch::base_dir'),
) {

    class { '::codesearch':
        base_dir => $base_dir,
    }
}
