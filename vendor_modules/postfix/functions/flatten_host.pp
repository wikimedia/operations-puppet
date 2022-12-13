# Flatten a host structure to a string.
#
# @param host The host to flatten, `undef` is passed through.
#
# @return [Optional[String]] The flattened string.
#
# @example
#   postfix::flatten_host('2001:db8::1')
#   postfix::flatten_host(['192.0.2.1', 389])
#
# @since 2.0.0
function postfix::flatten_host(Optional[Variant[Postfix::Type::Lookup::LDAP::Host, Postfix::Type::Lookup::MySQL::Host, Postfix::Type::Lookup::PgSQL::Host, Postfix::Type::Lookup::Memcache::Host]] $host) {

  $host ? {
    undef   => undef,
    default => type($host) ? {
      Type[Tuple]           => join($host.map |$x| {
        type($x) ? {
          Type[Bodgitlib::Host] => bodgitlib::enclose_ipv6($x), # lint:ignore:unquoted_string_in_selector FIXME
          default               => $x,
        }
      }, ':'),
      Type[Bodgitlib::Host] => bodgitlib::enclose_ipv6($host), # lint:ignore:unquoted_string_in_selector FIXME
      default               => $host,
    },
  }
}
