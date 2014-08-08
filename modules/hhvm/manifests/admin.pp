# == Class: hhvm::admin
#
# Configures Apache to proxy web requests for Port 9002 from
# internal IPs to HHVM's admin server port.
#
class hhvm::admin(
    $ensure = present,
    $port   = 9002,
) {
    include ::network::constants
    include ::apache::mod::proxy_fcgi

    if $port !~ /^\d+$/ { fail('port must be numeric') }

    apache::conf { 'hhvm_admin_port':
        content  => "Listen ${port}\n"
        priority => 1,
    }

    apache::site { 'hhvm_admin':
        content  => template('hhvm/hhvm-admin.conf.erb'),
    }
}
