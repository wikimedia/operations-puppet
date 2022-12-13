# Define a PostgreSQL lookup table.
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
#
# @see puppet_classes::postfix postfix
#
# @since 1.0.0
define postfix::lookup::pgsql (
  Array[Postfix::Type::Lookup::PgSQL::Host, 1] $hosts,
  String                                       $user,
  String                                       $password,
  String                                       $dbname,
  String                                       $query,
  Enum['present', 'absent']                    $ensure          = 'present',
  Stdlib::Absolutepath                         $path            = $title,
  Optional[String]                             $result_format   = undef,
  Optional[Array[String, 1]]                   $domain          = undef,
  Optional[Integer[0]]                         $expansion_limit = undef,
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
    content => template("${module_name}/pgsql.cf.erb"),
  }

  if $ensure != 'absent' and has_key($postfix::lookup_packages, 'pgsql') {
    $pgsql_package = $postfix::lookup_packages['pgsql']
    ensure_packages([$pgsql_package])
    Package[$pgsql_package] -> File[$path]
  }
}
