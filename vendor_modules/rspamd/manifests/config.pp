# rspamd::config
# ===========================
#
# @summary this type manages a single config entry
# 
# Rspamd uses its own UCL (Unified Configuration Language) format. This format
# basically allows to define a hierarchy of configuration objects.
#
# Since in puppet, we want to map each single config entry as its own resource,
# the hierarchy has been "flattened" to hierarchical keys.
#
# A key/value pair `foo = bar` nested in a `section` object, would look like 
# this in UCL:
#
# ```json
# section {
#   foo = bar
# }
# ```
#
# To reference this key in a rspam::config variable, you would use the 
# notation `section.foo`.
#
# UCL also allows to define arrays, by specifying the same key multiple times.
# To map this feature to a flattened key name, we use a numerical index in
# brackets.
# For example, this UCL snippet
#
# ```json
# statfile {
#   token = "BAYES_HAM"
# }
# statfile {
#   token = "BAYES_SPAM"
# }
# ```
#
# would be mapped to
#
# ```
# statfile[0].token = "BAYES_HAM"
# statfile[1].token = "BAYES_SPAM"
# ```
# 
# Title/Name format
# ------------
# 
# This module manages keeps Rspamd's default configuration untouched, and manages
# only local override config files. This matches the procedure recommended by the
# Rspamd authors.
#
# To specify which file a config entry should got to, you can use the `file` 
# parameter.
#
# For convenience reasons, however, this resource also allows to encode the values 
# for $sections, $key, and $file into the resource's name (which is usally the same as 
# its title).
#
# If the $name of the resource matches the format "<file>:<sections>.<name>", and all
# of $file, $sections, and $key have not been specified, the values from the name are 
# used.
# This simplifies creating unique resources for identical settings in different 
# files.
#
# @param sections
#   An array of section names that define the hierarchical name of this key.
#   E.g. `["classifier", "bayes"] to denote the `classifier "bayes" {` section.
#
#   If arrays of values are required (including arrays of maps, i.e. multiple 
#   sections with the same name), the key must be succeeded by an bracketed index,
#   e.g.
#
#   ```
#   sections => ["statfile[0]"],
#   key      => "token",
#   value    => "BAYES_HAM",
#
#   sections => ["statifle[1]"],
#   key      => "token",
#   value    => "BAYES_SPAM",
#   ```
#
# @param key
#   The key name of the config setting. The key is expected as a single non-hierachical 
#   name without any sections/maps.
#
# @param file
#   The file to put the value in. This module keeps Rspamd's default configuration
#   and makes use of its overrides. The value of this parameter must not include
#   any path information. If it contains no dot, `.conf` will be appended.
#   E.g. `bayes-classifier`
# 
# @param value
#   the value of this config entry. See `type` for allowed types.
#
# @param type
#   The type of the value, can be `auto`, `string`, `number`, `boolean`.
#
#   The default, `auto`, will try to determine the type from the input value:
#   Numbers and strings looking like supported number formats (e.g. "5", "5s", "10min",
#   "10Gb", "0xff", etc.) will be output literally.
#   Booleans and strings looking like supported boolean formats (e.g. "on", "off", 
#   "yes", "no", "true", "false") will be output literally.
#   Everything else will be output as a strings, unquoted if possible but quoted if
#   necessary. Multi-line strings will be output as <<EOD heredocs.
#   
#   If you require string values that look like numbers or booleans, explicitly
#   specify type => 'string'
#
# @param mode
#   Can be `merge` or `override`, and controls whether the config entry will be
#   written to `local.d` or `override.d` directory.
#
# @param comment
#   an optional comment that will be written to the config file above the entry
#
# @param ensure
#   whether this entry should be `present` or `absent`. Usually not needed at all,
#   because the config file will be fully managed by puppet and re-created each time.
#
# @author Bernhard Frauendienst <puppet@nospam.obeliks.de>
#
define rspamd::config (
  Any $value,
  Rspamd::Ucl::ValueType $type      = 'auto',
  Enum['merge', 'override'] $mode   = 'merge',
  Enum['present', 'absent'] $ensure = 'present',
  Optional[String] $file            = undef,
  Optional[Array[String]] $sections = undef,
  Optional[String] $key             = undef,
  Optional[String] $comment         = undef,
) {
  if (!$key and !$sections and !$file and $name =~ /\A([^:]+):(.+\.)?([^.]+)\z/) {
    $configfile = $1
    $configsections = $2 ? {
      Undef => [],
      default => split($2, '\.'),
    }
    $configkey = $3
  } else {
    $configfile = $file
    $configsections = pick($sections, [])
    $configkey = pick($key, $name)
  }
  unless $configfile {
    fail("Could not detect file name in resource title ${title}, must specify one explicitly")
  }

  $folder = $mode ? {
    'merge' => 'local.d',
    'override' => 'override.d',
  }
  $full_filename = $configfile ? {
    /\./    => $configfile,
    default => "${configfile}.conf",
  }
  $full_file = "${rspamd::config_path}/${folder}/${full_filename}"

  $full_key = join($configsections + $configkey, '/')
  rspamd::ucl::config { "rspamd config ${full_file} ${full_key}":
    ensure   => $ensure,
    file     => $full_file,
    sections => $configsections,
    key      => $configkey,
    value    => $value,
    type     => $type,
    comment  => $comment,
    notify   => Service['rspamd'],
  }
}
