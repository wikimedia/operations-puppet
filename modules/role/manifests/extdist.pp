# = Class: role::extdist
#
# This class sets up a tarball generator for the Extension Distributor
# extension enabled on mediawiki.org.
#
class role::extdist {

    if debian::codename::le('bullseye') {
        require ::profile::labs::lvm::srv
    }

    class { '::extdist': }
}
