# Definition: xinetd::service
#
# sets up a xinetd service
# all parameters match up with xinetd.conf(5) man page
#
# Parameters:
#   $port           - required - determines the service port
#   $server         - required - determines the executable for this service
#   $ensure         - optional - defaults to 'present'
#   $cps            - optional
#   $flags          - optional
#   $per_source     - optional
#   $server_args    - optional
#   $log_on_failure - optional - may contain any combination of
#                       'HOST', 'USERID', 'ATTEMPT'
#   $disable        - optional - defaults to 'no'
#   $socket_type    - optional - defaults to 'stream'
#   $protocol       - optional - defaults to 'tcp'
#   $user           - optional - defaults to 'root'
#   $group          - optional - defaults to 'root'
#   $instances      - optional - defaults to 'UNLIMITED'
#   $wait           - optional - based on $protocol
#                       will default to 'yes' for udp and 'no' for tcp
#   $bind           - optional - defaults to '0.0.0.0'
#   $service_type   - optional - type setting in xinetd
#                       may contain any combinarion of 'RPC', 'INTERNAL',
#                       'TCPMUX/TCPMUXPLUS', 'UNLISTED'
#
# Actions:
#   setups up a xinetd service by creating a file in /etc/xinetd.d/
#
# Requires:
#   $server must be set
#   $port must be set
#
# Sample Usage:
#   # setup tftp service
#   xinetd::service { 'tftp':
#     port        => '69',
#     server      => '/usr/sbin/in.tftpd',
#     server_args => '-s $base',
#     socket_type => 'dgram',
#     protocol    => 'udp',
#     cps         => '100 2',
#     flags       => 'IPv4',
#     per_source  => '11',
#   } # xinetd::service
#
define xinetd::service (
  $port,
  $server,
  $ensure         = present,
  $cps            = undef,
  $flags          = undef,
  $log_on_failure = undef,
  $per_source     = undef,
  $server_args    = undef,
  $disable        = 'no',
  $socket_type    = 'stream',
  $protocol       = 'tcp',
  $user           = 'root',
  $group          = 'root',
  $instances      = 'UNLIMITED',
  $wait           = undef,
  $bind           = '0.0.0.0',
  $service_type   = undef
) {

  if $wait {
    $mywait = $wait
  } else {
    $mywait = $protocol ? {
      tcp => 'no',
      udp => 'yes'
    }
  }

  file { "/etc/xinetd.d/${name}":
    ensure  => $ensure,
    content => template('xinetd/service.erb'),
    notify  => Service['xinetd'],
  }
}
