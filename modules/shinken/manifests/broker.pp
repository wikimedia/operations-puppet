# Class: shinken::broker
#
#    ## Optional
#    manage_arbiters     <%= @manage_arbiters %>; Take data from Arbiter. There should be only one
#    manage_sub_realms   <%= @manage_sub_realms %>; Does it take jobs from schedulers of sub-Realms?
#    timeout             <%= @timeout %>; Ping timeout
#    data_timeout        <%= @data_timeout %>; Data send timeout
#    max_check_attempts  <%= @max_check_attempts %>; If ping fails N or more, then the node is dead
#    check_interval      <%= @check_interval %>; Ping node every N seconds
# Install, configure and ensure running for shinken broker daemon 
class shinken::broker(
    $broker_name         = $::fqdn,
    $listen_address      = $::ipaddress,
    $spare               = 0,
    $realm               = 'All',
    $manage_arbiters     = 1,
    $manage_sub_realms   = 1,
    $timeout             = 3,
    $data_timeout        = 120,
    $max_check_attempts  = 3,
    $check_interval      = 60,
    $modules             = ['webui, pickle-retention-broker'],
) {
    shinken::daemon { "broker-${::fqdn}":
        daemon      => 'broker',
        port        => 7772,
        conf_file   => '/etc/shinken/daemons/brokerd.ini',
    }
}
