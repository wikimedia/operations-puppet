# == Class: hhvm::status
#
# Configures Apache to proxy web requests for </hhvm-status> from
# internal IPs to HHVM's admin server port.
#
class hhvm::status {
    include ::network::constants
    include ::apache::mod::proxy_fcgi

    apache::conf { 'hhvm_status':
        content => template('hhvm/hhvm-status.conf.erb'),
    }
}
