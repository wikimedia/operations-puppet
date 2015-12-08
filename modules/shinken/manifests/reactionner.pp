# Class: shinken::reactionner
#
#    reactionner_name
#    address
#    ## Optional
#    manage_sub_realms   0   ; Does it take jobs from schedulers of sub-Realms?
#    min_workers         0   ; Starts with N processes (0 = 1 per CPU)
#    max_workers         0   ; No more than N processes (0 = 1 per CPU)
#    processes_by_worker 256 ; Each worker manages N checks
#    polling_interval    1   ; Get jobs from schedulers each N minutes
#    timeout             3   ; Ping timeout
#    data_timeout        120 ; Data send timeout
#    max_check_attempts  3   ; If ping fails N or more, then the node is dead
#    check_interval      60  ; Ping node every N seconds
# Install, configure and ensure running for shinken reactionner daemon
class shinken::reactionner(
    $reactionner_name    = $::fqdn,
    $listen_address      = $::ipaddress,
    $spare               = 0,
    $realm               = 'All',
    $manage_sub_realms   = 0,
    $min_workers         = 0,
    $max_workers         = 0,
    $polling_interval    = 1,
    $timeout             = 3,
    $data_timeout        = 120,
    $max_check_attempts  = 3,
    $check_interval      = 60,
    $modules             = [],
) {
    shinken::daemon { "reactionner-${::fqdn}":
        daemon      => 'reactionner',
        port        => 7769,
        conf_file   => '/etc/shinken/daemons/reactionnerd.ini',
    }
}
