# == Define misc::limn::instance
# Sets up a limn instance as well as a
# limn instance proxy.  This define
# uses $::realm to infer an appropriate
# default $server_name and $server_aliases.
#
# == Parameters:
# $port            - limn port
# $server_name     - ServerName for limn instance proxy.     Default it to infer from $name and $::realm.
# $server_aliases  - ServerAliases for limn instance proxy.  Default is to infer from $name and $::realm.
#
# == Example
# misc::limn::instance { 'reportcard': }
#
define misc::limn::instance($port = 8081, $server_name = undef, $server_aliases = undef) {
  limn::instance { $name:
    port => $port,
  }

  $default_server_name = $::realm ? {
    'production' => "${name}.wikimedia.org",
    'labs'       => "${name}.wmflabs.org",
  }

  $default_server_aliases = $::realm ? {
    'production' => '',
    'labs'       => "${name}.instance-proxy.wmflabs.org"
  }

  $servername = $server_name ? {
    undef   => $default_server_name,
    default => $server_name,
  }
  $serveraliases = $server_aliases ? {
    undef   => $default_server_aliases,
    default => $server_aliases,
  }

  limn::instance::proxy { $name:
    limn_port      => $port,
    server_name    => $servername,
    server_aliases => $serveraliases,
  }
}
