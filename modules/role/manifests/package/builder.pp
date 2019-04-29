# == Class: role::package::builder
#
# Role for package_builder
#
# filtertags: labs-project-deployment-prep labs-project-packaging labs-project-tools
class role::package::builder {
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::package_builder

    system::role { 'package::builder':
        description => 'Debian package builder'
    }
}
