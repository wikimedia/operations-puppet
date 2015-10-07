# = Class: wdq_mm::lb
#
# Simple nginx based loadbalancer for wdq-mm
class wdq_mm::lb(
    $realservers = [],
) {
    nginx::site { 'wdq-mm-lb':
        content => template('wdq_mm/lb.nginx.erb'),
    }
}
