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
# [*destination*]
#   The directory where the mtail script will be installed provided as a
#   string. Defaults to '/etc/mtail'.
#
define mtail::program(
    $ensure      = present,
    $content     = undef,
    $source      = undef,
    $destination = '/etc/mtail',
) {
    validate_ensure($ensure)
    validate_absolute_path($destination)

    include ::mtail

    $basename = regsubst($title, '\W', '-', 'G')
    $filename = "${destination}/${basename}.mtail"

    file { $filename:
        ensure  => $ensure,
        content => $content,
        source  => $source,
    }
}
