# == Class: role::package::builder
#
# Role for package_builder
#
class role::package::builder {
    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::package_builder

    system::role { 'package::builder':
        description => 'Debian package builder'
    }
}
