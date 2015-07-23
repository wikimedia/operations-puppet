# == Class: hhvm::admin
#
# Configures Apache to proxy web requests on a specific port
# from internal IPs to HHVM's admin server port.
#
# === Parameters
#
# [*port*]
#   Port the admin site should listen on (default: 9002).
#
class hhvm::admin(
    $ensure = present,
    $port   = 9002,
) {
    include ::network::constants
    include ::apache::mod::proxy_fcgi

    if $port !~ /^\d+$/ { fail('port must be numeric') }

    apache::conf { 'hhvm_admin_port':
        ensure   => $ensure,
        content  => "Listen ${port}\n",
        priority => 1,
    }

    apache::site { 'hhvm_admin':
        ensure  => $ensure,
        content => template('hhvm/hhvm-admin.conf.erb'),
    }

    ferm::service { 'hhvm_admin':
        proto  => 'tcp',
        port   => $port,
        srange => '$INTERNAL',
    }
}
