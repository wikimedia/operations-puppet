# == Class role::pybal::testing
#
# Class for a pybal test host

class role::pybal::testing {
    include ::pybal
    include profile::pybal::testing
}
