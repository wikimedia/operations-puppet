#
# force apt and friends to instruct dpkg to keep old conffiles during upgrades
#
class apt::dpkg-confold {
    apt::conf { 'dpkg-confold':
        ensure   => $ensure,
        priority => '00',
        key      => 'Ddpkg::Options::',
        value    => '{ "--conf-old"; }',
    }
}
