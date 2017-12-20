# ORES worker
class role::ores::worker {

    system::role { $name: }

    include ::standard
    include ::profile::base::firewall
    include ::profile::ores::worker
}
