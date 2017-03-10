# === Define logrotate::rule
#
# Provides a common template that can be used by different applications to
# configure log rotation.
#
# The parameter of this class map directly to the corresponding logrotate
# options.
define logrotate::rule (
    $ensure         = present,
    $file_pattern   = undef,
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
    logrotate::conf { $title:
        ensure  => $ensure,
        content => template('logrotate/logrotate.erb'),
    }
}
