# == Class role::zuul::install
#
# Wrapper around ::zuul class which is needed by both merger and server roles
# that can in turn be installed on the same node. Prevent a duplication error.
#
class role::zuul::install {

    include role::zuul::configuration

    class { '::zuul': }
}
