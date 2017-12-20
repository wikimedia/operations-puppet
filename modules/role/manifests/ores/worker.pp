# ORES worker
class role::ores::worker {

    system::role { $name: }
 
    include ::standard
    include ::profile::base::firewall
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
