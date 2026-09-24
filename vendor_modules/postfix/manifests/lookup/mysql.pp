# Define a MySQL lookup table.
#
# @param hosts
# @param user
# @param password
# @param dbname
# @param query
# @param ensure
# @param path
# @param result_format
# @param domain
# @param expansion_limit
# @param option_file
# @param option_group
# @param tls_cert
# @param tls_key
# @param tls_ca_cert_file
# @param tls_ca_cert_dir
# @param tls_verify_cert
#
# @see puppet_classes::postfix postfix
#
# @since 1.0.0
define postfix::lookup::mysql (
  Array[Postfix::Type::Lookup::MySQL::Host, 1] $hosts,
  String                                       $user,
  String                                       $password,
  String                                       $dbname,
  String                                       $query,
  Enum['present', 'absent']                    $ensure           = 'present',
  Stdlib::Absolutepath                         $path             = $title,
  Optional[String]                             $result_format    = undef,
  Optional[Array[String, 1]]                   $domain           = undef,
  Optional[Integer[0]]                         $expansion_limit  = undef,
  Optional[Stdlib::Absolutepath]               $option_file      = undef,
  Optional[String]                             $option_group     = undef,
  Optional[Stdlib::Absolutepath]               $tls_cert         = undef,
  Optional[Stdlib::Absolutepath]               $tls_key          = undef,
  Optional[Stdlib::Absolutepath]               $tls_ca_cert_file = undef,
  Optional[Stdlib::Absolutepath]               $tls_ca_cert_dir  = undef,
  Optional[Boolean]                            $tls_verify_cert  = undef,
) {

  include postfix

  $_hosts = postfix::flatten_hosts($hosts)

  $_ensure = $ensure ? {
    'absent' => 'absent',
    default  => 'file',
  }

  file { $path:
    ensure  => $_ensure,
    owner   => 0,
    group   => 0,
    mode    => '0600',
    content => template("${module_name}/mysql.cf.erb"),
  }

  if $ensure != 'absent' and 'mysql' in $postfix::lookup_packages {
    $mysql_package = $postfix::lookup_packages['mysql']
    ensure_packages([$mysql_package])
    Package[$mysql_package] -> File[$path]
  }
}
