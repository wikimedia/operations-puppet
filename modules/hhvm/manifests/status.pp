# == Class: hhvm::status
#
# Configures Apache to proxy web requests for Port 9002 from
# internal IPs to HHVM's admin server port.
#
class hhvm::status ($ensure = 'present', $port = 9002){
    include ::network::constants
    include ::apache::mod::proxy_fcgi

    apache::conf { 'hhvm_admin_port':
        ensure   => $ensure,
        priority => 1,
        content  => "Listen ${port}\n"
    }

    apache::site { 'hhvm_status':
        ensure   => $ensure,
        content  => template('hhvm/hhvm-status.conf.erb'),
        priority => 99,
    }
}
