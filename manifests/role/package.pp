# == Class: role::package::pbuilder
#
# Basic role wrapper around misc::package-pbuilder and suitable for production
#
class role::package::builder {

    if $::realm == 'labs' {
        fail( 'On labs please use package::builder::labs instead')
    }

    system::role { 'role::package::builder': description => 'Debian package builder' }

    include misc::package-builder
}

# == Class: package::pbuilder::labs
#
# Role wrapper around misc::package-pbuilder suitable for labs. Since pbuilder
# use a fairly large amount of disk space and labs instance in eqiad have a
# pretty much filled out 2GB partition for /var, we have to mount the remaining
# disk space on /mnt and point pbuilder to it.
#
# This class depends on role::labs::lvm::mnt to provide the additional disk
# space at /mnt.  You must include it.
#
class role::package::builder::labs {

    if $::realm == 'production' {
        fail( 'On production please use package::builder instead')
    }

    system::role { 'role::package::builder::labs': description => 'Debian package builder on labs' }

    # Changing this would need manual cleanup on all labs instance using
    # this class!
    $pbuilder_root_labs = '/mnt/pbuilder'

    file { $pbuilder_root_labs:
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0775',
        require => Class['role::labs::lvm::mnt']
    }

    class { 'misc::package-builder':
        pbuilder_root => $pbuilder_root_labs,
        require       => File[$pbuilder_root_labs],
    }

}
