# = Class: role::extdist::extension
#
# This class sets up a tarball generator for the Extension Distributor
# extension enabled on mediawiki.org.
#
class role::extdist::extension {

    include role::labs::lvm::srv

    class { '::extdist':
        require => Mount['/srv']
    }
}
