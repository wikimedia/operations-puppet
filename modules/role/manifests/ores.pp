# ORES
class role::ores {

    system::role { 'ores':
        description => 'ORES service'
    }

    include ::standard
    include ::profile::base::firewall
    include role::lvs::realserver

    include ::profile::ores::worker
    include ::profile::ores::web
}
