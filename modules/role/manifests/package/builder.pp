# == Class: role::package::builder
#
# Role for package_builder
#
class role::package::builder {
    include profile::base::production
    include profile::firewall
    include profile::package_builder
}
