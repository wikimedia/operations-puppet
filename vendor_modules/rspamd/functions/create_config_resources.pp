# Function: rspamd::create_config_resources()
# ==================
#
# @summary create rspamd::config resources from a nested hash (e.g. from hiera)
#
# Create rspamd::config resources from a nested hash, suitable for
# conveniently loading values from hiera.
# The key-value pairs from the hash represent config keys and values
# passed to rspamd::config for simple values, Hash values recursively
# create nested sections. Arrays that only contain Hash values are 
# created as multi-value keys (or "duplicate sections"), while all 
# other arrays are printed inline (e.g. [a,b,c]).
# 
# @param config_hash a hash of (non-hierarchical) key names mapped to values
# @param params      a hash of params passed to rspamd::config (must not include :sections, :key, or :value)
# @param sections    the section names of the hierarchical key, will usually only be specified 
#   on recursive calls from within this function itself
#
# @see rspamd::create_config_file_resources
# @see rspamd::config
#
# @author Bernhard Frauendienst <puppet@nospam.obeliks.de>
#
function rspamd::create_config_resources(Hash[String, NotUndef] $config_hash, Hash $params = {}, Array[String] $sections = []) {
  $config_hash.each |$key, $value| {
    case $value {
      Hash: {
        rspamd::create_config_resources($value, $params, $sections + $key)
      }
      Array[Hash]: {
        $indexed_hash = $value.map |$index, $v| {
          { "${key}[${index}]" => $v }
        }.reduce({}) |$a,$b| { $a + $b }
        rspamd::create_config_resources($indexed_hash, $params, $sections)
      }
      default: {
        rspamd::config { "${params[file]}:${join($sections + $key, '.')}":
          sections => $sections,
          key      => $key,
          value    => $value,
          *        => $params,
        }
      }
    }
  }
}
