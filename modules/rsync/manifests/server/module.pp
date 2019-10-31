# Definition: rsync::server::module
#
# sets up a rsync server
#
# Parameters:
#   $path            - path to data
#   $comment         - rsync comment
#   $read_only       - yes||no, defaults to yes
#   $write_only      - yes||no, defaults to no
#   $list            - yes||no, defaults to yes
#   $uid             - uid of rsync server, defaults to 0
#   $gid             - gid of rsync server, defaults to 0
#   $incoming_chmod  - incoming file mode, defaults to 0644
#   $outgoing_chmod  - outgoing file mode, defaults to 0644
#   $max_connections - maximum number of simultaneous connections allowed, defaults to 0
#   $lock_file       - file used to support the max connections parameter, defaults to /var/run/rsyncd.lock
#    only needed if max_connections > 0
#   $secrets_file    - path to the file that contains the username:password pairs used for authenticating this module
#   $auth_users      - list of usernames that will be allowed to connect to this module (must be undef or an array)
#   $hosts_allow     - list of patterns allowed to connect to this module (man 5 rsyncd.conf for details, must be undef or an array)
#   $hosts_deny      - list of patterns allowed to connect to this module (man 5 rsyncd.conf for details, must be undef or an array)
#   $chroot          - chroot to the destination before starting the rsync.  enabled by default.
#   $auto_ferm       - If enabled and if $hosts_allow is set, generate a ferm service which restricts access to the allowed hosts
#   $auto_ferm_ipv6  - If auto_ferm is used and this option is enabled, ferm rules are also generated for ipv6
#
#   sets up an rsync server
#
# Requires:
#   $path must be set
#
# Sample Usage:
#   # setup default rsync repository
#   rsync::server::module { 'repo':
#     path    => $base,
#     require => File[$base],
#   }
#
define rsync::server::module (
  $path,
  $ensure          = present,
  $comment         = undef,
  $read_only       = 'yes',
  $write_only      = 'no',
  $list            = 'yes',
  $uid             = '0',
  $gid             = '0',
  $incoming_chmod  = '0644',
  $outgoing_chmod  = '0644',
  $max_connections = '0',
  $lock_file       = '/var/run/rsyncd.lock',
  $chroot          = true,
  $auto_ferm       = false,
  $auto_ferm_ipv6  = false,
  $secrets_file    = undef,
  $auth_users      = undef,
  $hosts_allow     = undef,
  $hosts_deny      = undef,
){
  include ::rsync::server

  file { "${rsync::server::rsync_fragments}/frag-${name}":
    ensure  => $ensure,
    content => template('rsync/module.erb'),
    notify  => Exec['compile fragments'],
  }

  if $auto_ferm and $hosts_allow {
      $hosts_allow_ferm = join($hosts_allow, ' ')

      # rsync::server is always used with include semantics, so we must do this.
      $port = lookup('rsync::server::wrap_with_stunnel') ? {  # lint:ignore:wmf_styleguide
          true  => '1873',
          false => '873',
      }

      ferm::service { "rsyncd_access_${name}":
          ensure => $ensure,
          proto  => 'tcp',
          port   => $port,
          srange => "@resolve((${hosts_allow_ferm}))",
      }

      if $auto_ferm_ipv6 {
          ferm::service { "rsyncd_access_${name}_ipv6":
              ensure => $ensure,
              proto  => 'tcp',
              port   => $port,
              srange => "@resolve((${hosts_allow_ferm}),AAAA)",
          }
      }
  }
}
