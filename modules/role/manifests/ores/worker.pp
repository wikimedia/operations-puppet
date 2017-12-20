# ORES worker
class role::ores::worker {
    include ::standard
    include ::base::firewall

    include ::profile::ores::worker

    ferm::service { 'ores-queue':
        proto => 'tcp',
        port  => '6379',
    }
    ferm::service { 'ores-cache':
        proto => 'tcp',
        port  => '6380',
    }
}
