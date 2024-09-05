# == Class role::sessionstore
#
# Configures the production session storage cluster
class role::sessionstore {
    include profile::firewall
    include profile::base::production
    include profile::sessionstore
    # lint:ignore:wmf_styleguide - It is neither a role nor a profile
    include passwords::cassandra
    # lint:endignore
    include profile::cassandra
}
