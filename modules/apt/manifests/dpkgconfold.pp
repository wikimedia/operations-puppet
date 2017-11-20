#
# force apt and friends to instruct dpkg to keep old conffiles during upgrades
#
class apt::dpkgconfold {
    apt::conf { 'dpkgconfold':
        ensure   => present,
        priority => '00',
        key      => 'Dpkg::Options::',
        value    => '{ "--conf-old"; }',
    }
}
