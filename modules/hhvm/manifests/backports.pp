# == Class hhvm::backports
#
# Recent hhvm versions requires liboost 1.0.49 which is not shipped by
# Ubuntu Precise. We rely on a third-party PPA.
#
# Can only be applied on Labs.
#
# You most probably want to use the 'hhvm' puppet class instead.
class hhvm::backports {
    if $::realm != 'labs' {
        fail( 'hhvm::backports may only be deployed to Labs.' )
    }

    apt::repository { 'boost_backports':
        uri        => 'http://ppa.launchpad.net/mapnik/boost/ubuntu',
        dist       => 'precise',
        components => 'main',
        keyfile    => 'puppet:///files/misc/boost-backports.key',
    }
}
