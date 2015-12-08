# Class: shinken::scheduler
#
#    scheduler_name
#    address      
#
#    ## Optional
#    weight 1
#    timeout             3   ; Ping timeout
#    data_timeout        120 ; Data send timeout
#    max_check_attempts  3   ; If ping fails N or more, then the node is dead
#    check_interval      60  ; Ping node every N seconds
# Install, configure and ensure running for shinken receiver daemon
class shinken::scheduler(
    $scheduler_name      = $::fqdn,
    $listen_address      = $::ipaddress,
    $spare               = 0,
    $realm               = 'All',
    $weight              = 1,
    $timeout             = 3,
    $data_timeout        = 120,
    $max_check_attempts  = 3,
    $check_interval      = 60,
    $modules             = ['pickle-retention-scheduler'],
){
    shinken::daemon { "scheduler-${::fqdn}":
        daemon      => 'scheduler',
        port        => 7768,
        conf_file   => '/etc/shinken/daemons/schedulerd.ini'
    }
}
