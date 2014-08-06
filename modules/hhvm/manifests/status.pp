# == Class: hhvm::status
#
# Configures Apache to proxy web requests for Port 9002 from
# internal IPs to HHVM's admin server port.
#
class hhvm::status ($port = 9002){
    include ::network::constants
    include ::apache::mod::proxy_fcgi

    file_line { 'add_hhvm_monitoring_port':
        ensure  => present,
        path    => '/etc/apache2/ports.conf',
        line    => "Listen ${port}",
        require => Package['apache2']
    }

    apache2::site { 'hhvm_status':
        content  => template('hhvm/hhvm-status.conf.erb'),
        priority => 99,
    }
}
