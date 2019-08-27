# ORES
class role::ores {

    system::role { 'ores':
        description => 'ORES service'
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::lvs::realserver

    include ::profile::ores::worker
    include ::profile::ores::web
}
