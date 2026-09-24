# Define an LDAP lookup table.
#
# @example Configure Postfix for virtual mailbox hosting using LDAP to provide the various lookup tables
#   class { 'postfix':
#     virtual_mailbox_base    => '/var/mail/vhosts',
#     virtual_mailbox_domains => ['ldap:/etc/postfix/virtualdomains.cf'],
#     virtual_mailbox_maps    => ['ldap:/etc/postfix/virtualrecipients.cf'],
#     virtual_minimum_uid     => 100,
#     virtual_uid_maps        => 'static:5000',
#     virtual_gid_maps        => 'static:5000',
#   }
#
#   # Specify connection defaults to enable sharing as per LDAP_README
#   Postfix::Lookup::Ldap {
#     server_host => ['ldap://192.0.2.1'],
#     search_base => 'dc=example,dc=com',
#     bind_dn     => 'cn=Manager,dc=example,dc=com',
#     bind_pw     => 'secret',
#     version     => 3,
#   }
#
#   postfix::lookup::ldap { '/etc/postfix/virtualdomains.cf':
#     query_filter     => '(associatedDomain=%s)',
#     result_attribute => ['associatedDomain'],
#   }
#
#   postfix::lookup::ldap { '/etc/postfix/virtualrecipients.cf':
#     query_filter     => '(mail=%s)',
#     result_attribute => ['mail'],
#   }
#
# @param search_base
# @param path
# @param ensure
# @param server_host
# @param server_port
# @param timeout
# @param query_filter
# @param result_format
# @param domain
# @param result_attribute
# @param special_result_attribute
# @param terminal_result_attribute
# @param leaf_result_attribute
# @param scope
# @param bind
# @param bind_dn
# @param bind_pw
# @param recursion_limit
# @param expansion_limit
# @param size_limit
# @param dereference
# @param chase_referrals
# @param version
# @param debuglevel
# @param sasl_mechs
# @param sasl_realm
# @param sasl_authz_id
# @param sasl_minssf
# @param start_tls
# @param tls_ca_cert_dir
# @param tls_ca_cert_file
# @param tls_cert
# @param tls_key
# @param tls_require_cert
# @param tls_random_file
# @param tls_cipher_suite
#
# @see puppet_classes::postfix postfix
#
# @since 1.0.0
define postfix::lookup::ldap (
  Bodgitlib::LDAP::DN                                        $search_base,
  Stdlib::Absolutepath                                       $path                      = $title,
  Enum['present', 'absent']                                  $ensure                    = 'present',
  Optional[Array[Postfix::Type::Lookup::LDAP::Host, 1]]      $server_host               = undef,
  Optional[Bodgitlib::Port]                                  $server_port               = undef,
  Optional[Integer[0]]                                       $timeout                   = undef,
  Optional[Bodgitlib::LDAP::Filter]                          $query_filter              = undef,
  Optional[String]                                           $result_format             = undef,
  Optional[Array[String, 1]]                                 $domain                    = undef,
  Optional[Array[String, 1]]                                 $result_attribute          = undef,
  Optional[Array[String, 1]]                                 $special_result_attribute  = undef,
  Optional[Array[String, 1]]                                 $terminal_result_attribute = undef,
  Optional[Array[String, 1]]                                 $leaf_result_attribute     = undef,
  Optional[Bodgitlib::LDAP::Scope]                           $scope                     = undef,
  Optional[Variant[Boolean, Enum['sasl', 'none', 'simple']]] $bind                      = undef,
  Optional[Bodgitlib::LDAP::DN]                              $bind_dn                   = undef,
  Optional[String]                                           $bind_pw                   = undef,
  Optional[Integer[1]]                                       $recursion_limit           = undef,
  Optional[Integer[0]]                                       $expansion_limit           = undef,
  Optional[Integer[0]]                                       $size_limit                = undef,
  Optional[Integer[0, 3]]                                    $dereference               = undef,
  Optional[Boolean]                                          $chase_referrals           = undef,
  Optional[Integer[2, 3]]                                    $version                   = undef,
  Optional[Integer[0]]                                       $debuglevel                = undef,
  Optional[Array[String, 1]]                                 $sasl_mechs                = undef,
  Optional[String]                                           $sasl_realm                = undef,
  Optional[String]                                           $sasl_authz_id             = undef,
  Optional[Integer[0]]                                       $sasl_minssf               = undef,
  Optional[Boolean]                                          $start_tls                 = undef,
  Optional[Stdlib::Absolutepath]                             $tls_ca_cert_dir           = undef,
  Optional[Stdlib::Absolutepath]                             $tls_ca_cert_file          = undef,
  Optional[Stdlib::Absolutepath]                             $tls_cert                  = undef,
  Optional[Stdlib::Absolutepath]                             $tls_key                   = undef,
  Optional[Boolean]                                          $tls_require_cert          = undef,
  Optional[Stdlib::Absolutepath]                             $tls_random_file           = undef,
  Optional[String]                                           $tls_cipher_suite          = undef,
) {

  include postfix

  $_server_host = postfix::flatten_hosts($server_host)

  $_ensure = $ensure ? {
    'absent' => 'absent',
    default  => 'file',
  }

  file { $path:
    ensure  => $_ensure,
    owner   => 0,
    group   => 0,
    mode    => '0600',
    content => template("${module_name}/ldap.cf.erb"),
  }

  if $ensure != 'absent' and 'ldap' in $postfix::lookup_packages {
    $ldap_package = $postfix::lookup_packages['ldap']
    ensure_packages([$ldap_package])
    Package[$ldap_package] -> File[$path]
  }
}
