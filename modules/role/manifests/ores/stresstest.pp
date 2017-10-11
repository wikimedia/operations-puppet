# Temporary role class for T169246
class role::ores::stresstest {
    include ::standard
    include ::profile::base::firewall

    include ::profile::ores::worker
    include ::profile::ores::web

    ferm::service { 'ores-queue':
        proto => 'tcp',
        port  => '6379',
    }
    ferm::service { 'ores-cache':
        proto => 'tcp',
        port  => '6380',
    }
}
