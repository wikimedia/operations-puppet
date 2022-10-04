# Simple profile class for installing the proper version of kubectl
# NOTE: Resist the urge to just old it in some other profile, it's been split
# off in its own profile so that it can be reused in e.g. deployment servers
class profile::kubernetes::client (
    Boolean $packages_from_future = lookup('profile::kubernetes::client::packages_from_future', { default_value => false }),
) {
    class { 'k8s::client':
        packages_from_future => $packages_from_future,
    }
}
