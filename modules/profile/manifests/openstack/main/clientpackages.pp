class profile::openstack::main::clientpackages(
    String $version = hiera('profile::openstack::main::version'),
) {
    class { '::profile::openstack::base::clientpackages':
        version => $version,
    }
    contain '::profile::openstack::base::clientpackages'

    # we are moving away from require_package() in this factorization, so put
    # this here to have a minimal catalog diff. This could be dropped, but
    # probably better to just wait until we deprecate this deployment.
    # Why? because we switched to 'virtual-mysql-client', which is a more
    # robust way of expressing this dependency.
    $mainpackages = [
        'mysql-client-5.5',
        'mysql-common',
    ]

    package { $mainpackages:
        ensure => 'present',
    }
}
