# == Class: role::proton
#
# Role class for the Proton service
#
class role::proton {
    system::role { 'proton':
        description => 'Chromium-based PDF renderer',
    }
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::lvs::realserver

    include ::profile::proton
}
