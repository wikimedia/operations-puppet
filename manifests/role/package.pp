# == Class: role::package::pbuilder
#
# Basic role wrapper around misc::package-pbuilder and suitable for production
#
class role::package::builder {

    if $::realm == 'labs' {
        fail( 'Please do not use this class on labs')
    }

    system::role { 'role::package::builder': description => 'Debian package builder' }

    include misc::package-builder
}

