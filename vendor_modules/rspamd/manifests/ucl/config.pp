# rspamd::ucl::config
# ===========================
#
# @summary manages a single UCL (Universal Configuration Language) config entry
#
# @note This class is only for internal use, use rspam::config instead.
#
# @param file     the file to put the entry in
# @param key      the entry's key
# @param sections the entry's sections as an array
# @param value    the entry's value
# @param type     the type to enforce (or `auto` for auto-detection)
# @param comment  an optional comment to be printed above the entry
# @param ensure   whether the entry should be `present` or `absent`
#
# @see rspamd::config
#
# @author Bernhard Frauendienst <puppet@nospam.obeliks.de>
#
define rspamd::ucl::config (
  Stdlib::Absolutepath $file,
  String $key,
  $value,
  Array[String] $sections           = [],
  Rspamd::Ucl::ValueType $type      = 'auto',
  Enum['present', 'absent'] $ensure = 'present',
  Optional[String] $comment         = undef,
) {
  ensure_resource('rspamd::ucl::file', $file)

  $rsections = ['/'] + $sections
  $depth = length($sections)
  if ($depth > 0) {
    Integer[1,$depth].each |$i| {
      $section = join($rsections[0,$i+1], ' 03 ')
      $indent = sprintf("%${($i - 1)*2}s", '')

      # strip the [x] array qualifier
      $section_name = $sections[$i-1] ? {
        /^(.*)\[\d+\]$/ => $1,
        default         => $sections[$i-1]
      }
      ensure_resource('concat::fragment', "rspamd ${file} UCL config ${section} 01 section start", {
        target  => $file,
        content => "${indent}${section_name} {\n",
      })
      ensure_resource('concat::fragment', "rspamd ${file} UCL config ${section} 04 section end", { # ~ sorts last
        target  => $file,
        content => "${indent}}\n",
      })
    }
  }

  # now for the value itself
  $indent = sprintf("%${$depth*2}s", '')
  $section = join($rsections, ' 03 ')
  $entry_key = $key ? {
    /^(.*)\[\d+\]$/ => $1,
    default         => $key
  }

  if ($comment) {
    concat::fragment { "rspamd ${file} UCL config ${section} 02 ${key} 01 comment":
      target  => $file,
      content => join(suffix(prefix(split($comment, '\n'), "${indent}# "), "\n")),
    }
  }

  $printed_value = rspamd::ucl::print_config_value($value, $type)
  $semicolon = $printed_value ? {
    /\A<</  => '',
    default => ";\n"
  }

  concat::fragment { "rspamd ${file} UCL config ${section} 02 ${key} 02":
    target  => $file,
    content => "${indent}${entry_key} = ${printed_value}${semicolon}",
  }
}
