# @summary Wrapper for the HAProxy module. You probably do not need this in new code.
class haproxy::cloud::base () {
    class { 'haproxy':
        template => 'haproxy/cloud/haproxy.cfg.erb',
        logging  => true,
        # No Icinga support here
        monitor  => false,
    }
}
