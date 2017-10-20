# = Class: role::extdist
#
# This class sets up a tarball generator for the Extension Distributor
# extension enabled on mediawiki.org.
#
# filtertags: labs-project-extdist
class role::extdist {

    require ::profile::labs::lvm::srv

    class { '::extdist': }
}
