# == Define: mtail::program
#
# Install an mtail "program" to extract metrics from log files.
#
# === Parameters
#
# [*ensure*]
#   The usual metaparameter.
#
# [*content*]
#   The content of the file provided as a string. Either this or
#   'source' must be specified.
#
# [*source*]
#   The content of the file provided as a puppet:/// file reference.
#   Either this or 'content' must be specified.
#
define mtail::program(
    $ensure   = present,
    $content  = undef,
    $source   = undef,
) {
    validate_ensure($ensure)

    include ::mtail

    $basename = regsubst($title, '\W', '-', 'G')
    $filename = "/etc/mtail/${basename}.mtail"

    file { $filename:
        ensure  => $ensure,
        content => $content,
        source  => $source,
    }
}
