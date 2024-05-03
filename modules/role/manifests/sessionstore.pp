# == Class role::sessionstore
#
# Configures the production session storage cluster
class role::sessionstore {
    include profile::firewall
    include profile::base::production
    include profile::sessionstore
    include profile::cassandra
}
