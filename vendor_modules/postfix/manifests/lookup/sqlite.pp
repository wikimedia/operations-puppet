# Define an SQLite lookup table.
#
# @param dbpath
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
define postfix::lookup::sqlite (
  Stdlib::Absolutepath       $dbpath,
  String                     $query,
  Enum['present', 'absent']  $ensure          = 'present',
  Stdlib::Absolutepath       $path            = $title,
  Optional[String]           $result_format   = undef,
  Optional[Array[String, 1]] $domain          = undef,
  Optional[Integer[0]]       $expansion_limit = undef,
) {

  include postfix

  $_ensure = $ensure ? {
    'absent' => 'absent',
    default  => 'file',
  }

  file { $path:
    ensure  => $_ensure,
    owner   => 0,
    group   => 0,
    mode    => '0600',
    content => template("${module_name}/sqlite.cf.erb"),
  }

  if $ensure != 'absent' and 'sqlite' in $postfix::lookup_packages {
    $sqlite_package = $postfix::lookup_packages['sqlite']
    ensure_packages([$sqlite_package])
    Package[$sqlite_package] -> File[$path]
  }
}
