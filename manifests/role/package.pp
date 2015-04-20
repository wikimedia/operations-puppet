# == Class: role::package::builder
#
# Role for package_builder
#
class role::package::builder {
    include ::package_builder
    include base::firewall

    system::role { 'role::package::builder':
        description => 'Debian package builder'
    }
}
