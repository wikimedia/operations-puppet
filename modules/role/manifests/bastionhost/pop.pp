# bastion host for all users in a caching PoP
class role::bastionhost::pop {
    system::role { 'bastionhost::pop':
        description => 'Bastion host for all shell users in a caching Pop',
    }
    require ::role::bastionhost::general
    require ::role::installserver::tftp
    require ::role::prometheus::ops
    require ::role::ipmi::mgmt
}
