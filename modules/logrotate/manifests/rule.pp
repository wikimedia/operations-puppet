# === Define logrotate::rule
#
# Provides a common template that can be used by different applications to
# configure log rotation. See logrotate man page for detailed documentation.
#
# Most parameters of this class map directly to the corresponding logrotate
# options.
#
# [*frequency*]
#   frequency of log rotation, must be in [ 'daily', 'weekly', 'monthly', 'yearly' ].
#   default: undef
#
# [*size*]
#   Size after which to rotate, or maxsize if frequency is defined.
#   default: undef
#
define logrotate::rule (
    $file_glob,
    $ensure         = present,
    $frequency      = undef,
    $not_if_empty   = false,
    $date_yesterday = false,
    $copy_truncate  = false,
    $max_age        = undef,
    $rotate         = undef,
    $date_ext       = false,
    $compress       = false,
    $missing_ok     = false,
    $size           = undef,
    $no_create      = false,
    $post_rotate    = undef,
) {

    $valid_frequencies = [ 'daily', 'weekly', 'monthly', 'yearly' ]
    $valid_frequencies_text = join($valid_frequencies, ', ')

    if ($frequency != undef) and !($frequency in $valid_frequencies) {
        fail("\$frequency should be in [${valid_frequencies_text}] but is '${frequency}'")
    }
    validate_bool(
        $not_if_empty, $date_yesterday, $copy_truncate, $date_ext,
        $compress, $missing_ok, $no_create
    )

    if $max_age != undef {
        validate_integer($max_age)
    }
    if $rotate != undef {
        validate_integer($rotate)
    }

    $actual_size = $size ? {
        undef => undef,
        default => $frequency ? {
            undef   => "size ${size}",
            default => "maxsize ${size}",
        }
    }

    logrotate::conf { $title:
        ensure  => $ensure,
        content => template('logrotate/logrotate.erb'),
    }
}
