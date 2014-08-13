# == Define: salt::grain
#
# Set or remove a grain value.
#
# === Parameters
#
# [*grain*]
#   The name of the grain. For example, 'deployment-target'.
#   Defaults to the resource title.
#
# [*value*]
#   Value to set or remove from grain.
#
# [*ensure*]
#   If 'present', adds value to grain. If 'absent', removes it.
#   Defaults to 'present'.
#
# [*replace*]
#   If true, replaces the value in the grain. If false, it adds the value.
#   Defaults to true.
#
# === Examples
#
#  salt::grain { 'cluster':
#    value   => 'eqiad_text_cache',
#    replace => true,
#  }
#
define salt::grain(
    $value,
    $grain   = $title,
    $ensure  = present,
    $replace = false,
) {
    validate_ensure($ensure)
    validate_bool($replace)

    if $ensure == 'present' {
        if $replace { $subcommand = 'set' } else { $subcommand = 'add' }
        $onlyif     = undef
        $unless     = "/usr/local/sbin/grain-ensure contains ${grain} ${value}"
    } else {
        $subcommand = 'remove'
        $onlyif     = "/usr/local/sbin/grain-ensure contains ${grain} ${value}"
        $unless     = undef
    }

    exec { "ensure_${grain}_${value}":
        command => "/usr/local/sbin/grain-ensure ${subcommand} ${grain} ${value}",
        onlyif  => $onlyif,
        unless  => $unless,
    }
}
