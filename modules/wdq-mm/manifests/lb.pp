# = Class: wdq-mm::lb
#
# Simple nginx based loadbalancer for wdq-mm
class wdq-mm::lb(
    $realservers = [],
) {
    nginx::site { 'wdq-mm-lb':
        content => template('wdq-mm/lb.nginx.erb'),
    }
}
