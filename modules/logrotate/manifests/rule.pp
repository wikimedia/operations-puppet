# === Define logrotate::rule
#
# Provides a common template that can be used by different applications to
# configure log rotation.
#
# Most parameters of this class map directly to the corresponding logrotate
# options.
#
# [*periodicity*]
#   periodicity of log rotation, must be in [ 'daily', 'weekly', 'monthly', 'yearly' ].
#   default: undef
#
# [*size*]
#   Size after which to rotate, or maxsize if periodicity is defined.
#   default: undef
#
define logrotate::rule (
    $file_glob,
    $ensure         = present,
    $periodicity    = undef,
    $not_if_empty   = false,
    $daily          = false,
    $date_yesterday = false,
    $copy_truncate  = false,
    $max_age        = undef,
    $rotate         = undef,
    $date_ext       = false,
    $compress       = false,
    $delay_compress = false,
    $missing_ok     = false,
    $size           = undef,
    $no_create      = false,
    $post_rotate    = undef,
) {

    if ($periodicity != undef) and !($periodicity in [ 'daily', 'weekly', 'monthly', 'yearly' ]) {
        fail("\$periodicity should be in [ 'daily', 'weekly', 'monthly', 'yearly' ] but is ${periodicity}")
    }

    $actual_size = $size ? {
        undef => undef,
        default => $periodicity ? {
            undef   => "size ${size}",
            default => "maxsize ${size}",
        }
    }

    logrotate::conf { $title:
        ensure  => $ensure,
        content => template('logrotate/logrotate.erb'),
    }
}
