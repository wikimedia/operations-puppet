# Define a Memcache lookup table.
#
# @example Postscreen temporary whitelist
#   include memcached
#
#   class { 'postfix':
#     postscreen_cache_map => 'memcache:/etc/postfix/postscreen_cache',
#     proxy_write_maps     => ['btree:$data_directory/postscreen_cache'],
#     ...
#   }
#
#   postfix::lookup::memcache { '/etc/postfix/postscreen_cache':
#     memcache   => ['inet', '127.0.0.1', 11211],
#     backup     => 'btree:$data_directory/postscreen_cache',
#     key_format => 'postscreen:%s',
#     require    => Class['memcached'],
#   }
#
# @param ensure
# @param path
# @param memcache
# @param backup
# @param flags
# @param ttl
# @param key_format
# @param domain
# @param data_size_limit
# @param line_size_limit
# @param max_try
# @param retry_pause
# @param timeout
#
# @see puppet_classes::postfix postfix
#
# @since 2.0.0
define postfix::lookup::memcache (
  Enum['present', 'absent']                       $ensure          = 'present',
  Stdlib::Absolutepath                            $path            = $title,
  Optional[Postfix::Type::Lookup::Memcache::Host] $memcache        = undef,
  Optional[String]                                $backup          = undef,
  Optional[Integer[0]]                            $flags           = undef,
  Optional[Integer[0]]                            $ttl             = undef,
  Optional[String]                                $key_format      = undef,
  Optional[Array[String, 1]]                      $domain          = undef,
  Optional[Integer[0]]                            $data_size_limit = undef,
  Optional[Integer[0]]                            $line_size_limit = undef,
  Optional[Integer[0]]                            $max_try         = undef,
  Optional[Integer[0]]                            $retry_pause     = undef,
  Optional[Integer[0]]                            $timeout         = undef,
) {

  include postfix

  $_memcache = postfix::flatten_host($memcache)

  $_ensure = $ensure ? {
    'absent' => 'absent',
    default  => 'file',
  }

  file { $path:
    ensure  => $_ensure,
    owner   => 0,
    group   => 0,
    mode    => '0600',
    content => template("${module_name}/memcache.cf.erb"),
  }

  if $ensure != 'absent' and 'memcache' in $postfix::lookup_packages {
    $memcache_package = $postfix::lookup_packages['memcache']
    ensure_packages([$memcache_package])
    Package[$memcache_package] -> File[$path]
  }
}
