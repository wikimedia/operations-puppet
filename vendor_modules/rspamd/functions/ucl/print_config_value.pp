# Function: rspamd::ucl::print_config_value()
# ===================
#
# @summary returns a properly quoted UCL config value
# @param value the value to be printed
# @param type  the type to be enforced (or `auto` to detect from value)
#
# @return the formatted config value suitable for inclusion in a ucl config file
#
# @see puppet_classes::rspamd::config
#
# @author Bernhard Frauendienst <puppet@nospam.obeliks.de>
#
function rspamd::ucl::print_config_value($value, Rspamd::Ucl::ValueType $type = 'auto') {
  $re_number = /\A(\d+(\.\d+)?([kKmMgG]b?|s|min|d|w|y)?|0x[0-9A-F]+)\z/
  $re_boolean = /\A(true|false|on|off|yes|no)\z/
  $target_type = $type ? {
    'auto' => $value ? {
      $re_number => 'number',
      Numeric => 'number',
      $re_boolean => 'boolean',
      Boolean => 'boolean',
      Array => 'array',
      default => 'string',
    },
    default => $type,
  }

  case $target_type {
    'number': {
      case $value {
        $re_number, Numeric: {
          String($value)
        }
        default: {
          fail("Cannot convert ${value} to numeric UCL value.")
        }
      }
    }
    'boolean': {
      case $value {
        $re_boolean, Boolean: {
          String($value)
        }
        default: {
          fail("Cannot convert ${value} to boolean UCL value.")
        }
      }
    }
    'string': {
      case $value {
        /\n/: {
          $eod = $value ? {
            /^EOD$/ => "EOD${fqdn_rand(1000000)}",
            default => 'EOD',
          }
          "<<${eod}\n${value}\n${eod}\n"
        }
        $re_number, $re_boolean: {
          # Make sure strings that look like numbers and booleans aren't printed verbatim
          rspamd::ucl::quote_string_value($value)
        }
        /\A[A-Za-z0-9]+\z/: {
          $value
        }
        String: {
          rspamd::ucl::quote_string_value($value)
        }
        default: {
          # for everything else, convert to string, and then quote it
          rspamd::ucl::quote_string_value(String($value))
        }
      }
    }
    'array': {
      $_values = any2array($value)
      $_joined_values = join($_values.map|$v| { rspamd::ucl::print_config_value($v) }, ', ')
      "[ ${_joined_values} ]"
    }
    default: {
      fail("Invalid value type ${target_type}. This should not happen.")
    }
  }
}
