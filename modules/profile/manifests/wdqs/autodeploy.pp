class profile::wdqs::autodeploy (
    Stdlib::Absolutepath $package_dir = hiera('profile::wdqs::package_dir'),
) {
    require ::profile::wdqs

    class { '::wdqs::autodeploy':
        package_dir => $package_dir,
    }

}