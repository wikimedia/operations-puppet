# Function: rspamd::create_config_file_resources()
# =============
#
# @summary create {rspamd::config} resources from a nested hash (e.g. from hiera)
# 
# Create {rspamd::config} resources from a nested hash, suitable for
# conveniently loading values from hiera.
#
# The first level of keys is the config files to be written to, the
# values being the hierarchical values that will be passed to 
# the {rspamd::create_config_resources} function
# 
# @param configfile_hash a hash of config file names mapped to config hashes
# @param params          a hash of params passed to the {rspamd::config} resource (:file will be overridden)
#
# @see rspamd::create_config_resources
# @see rspamd::config
#
# @author Bernhard Frauendienst <puppet@nospam.obeliks.de>
#
function rspamd::create_config_file_resources(Hash[String, Hash] $configfile_hash, Hash $params = {}) {
  $configfile_hash.each |$key, $value| {
    $file_params = {
      file => $key
    } + $params
    rspamd::create_config_resources($value, $file_params)
  }
}
