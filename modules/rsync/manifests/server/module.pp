# @summary sets up a rsync server
#
# Parameters:
# @param path
#   path to data
# @param ensure
#   ensurable parameter
# @param comment
#   rsync comment
# @param read_only
#   yes||no, defaults to yes
# @param write_only
#   yes||no, defaults to no
# @param list
#   yes||no, defaults to yes
# @param uid
#   uid of rsync server, defaults to 0
# @param gid
#   gid of rsync server, defaults to 0
# @param incoming_chmod
#   incoming file mode, defaults to undef
# @param outgoing_chmod
#   outgoing file mode, defaults to undef
# @param max_connections
#   maximum number of simultaneous connections allowed, defaults to 0
# @param lock_file
#   file used to support the max connections parameter, defaults to
#   /var/run/rsyncd.lock only needed if max_connections > 0
# @param secrets_file
#   path to the file that contains the username:password pairs used for
#   authenticating this module
# @param auth_users
#   list of usernames that will be allowed to connect to this module (must be
#   undef or an array)
# @param hosts_allow
#   list of patterns allowed to connect to this module (man 5 rsyncd.conf for
#   details, must be undef or an array)
# @param hosts_deny
#   list of patterns allowed to connect to this module (man 5
#   rsyncd.conf for details, must be undef or an array)
# @param chroot
#   chroot to the destination before starting the rsync.  enabled by default.
# @param auto_firewall
#   If enabled and if $hosts_allow is set, generate a firewall service which restricts
#   access to the allowed hosts. This enables access via ipv4 and ipv6
#
# @example
#   rsync::server::module { 'repo':
#     path    => $base,
#     require => File[$base],
#   }
#
define rsync::server::module (
  Stdlib::Unixpath                        $path,
  Wmflib::Ensure                          $ensure          = present,
  Stdlib::Yes_no                          $read_only       = 'yes',
  Stdlib::Yes_no                          $write_only      = 'no',
  Stdlib::Yes_no                          $list            = 'yes',
  String[1]                               $uid             = '0',
  String[1]                               $gid             = '0',
  Variant[Integer, String[1]]             $max_connections = '0',
  Stdlib::Unixpath                        $lock_file       = '/var/run/rsyncd.lock',
  Boolean                                 $chroot          = true,
  Boolean                                 $auto_firewall   = false,
  Optional[Stdlib::Unixpath]              $secrets_file    = undef,
  Optional[String[1]]                     $comment         = undef,
  Optional[String[4]]                     $incoming_chmod  = undef,
  Optional[String[4]]                     $outgoing_chmod  = undef,
  Optional[Array[String]]                 $auth_users      = undef,
  Optional[Variant[String,Array[String]]] $hosts_allow     = undef,
  Optional[Variant[String,Array[String]]] $hosts_deny      = undef,
){
  include rsync::server

  if $hosts_allow {
    $hosts_allow_as_array = $hosts_allow ? {
      Array  => $hosts_allow,
      String => split($hosts_allow, /\s+/),
    }
    # To support stunnel, always accept from localhost.
    $frag_hosts_allow = ('localhost' in $hosts_allow_as_array) ? {
      false => $hosts_allow_as_array + 'localhost',
      true  => $hosts_allow_as_array,
    }
  }

  if $ensure == 'present' {
    concat::fragment { "${rsync::server::rsync_conf}-${name}":
      target  => $::rsync::server::rsync_conf,
      content => template('rsync/module.erb'),
    }
  }

  if $auto_firewall and $hosts_allow {
      firewall::service { "rsyncd_access_${name}":
          ensure => $ensure,
          proto  => 'tcp',
          port   => [873, 1873],
          srange => $hosts_allow,
      }
  }
}
