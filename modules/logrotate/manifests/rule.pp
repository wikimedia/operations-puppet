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
    String $file_glob,
    Wmflib::Ensure $ensure = present,
    Optional[Enum['daily', 'weekly', 'monthly', 'yearly']] $frequency = undef,
    Boolean $not_if_empty = false,
    Boolean $date_yesterday = false,
    Boolean $copy_truncate = false,
    Optional[Integer] $max_age = undef,
    Optional[Integer] $rotate = undef,
    Boolean $date_ext = false,
    Boolean $compress = false,
    Boolean $missing_ok = false,
    Optional[String] $size = undef,
    Boolean $no_create = false,
    Optional[String] $post_rotate = undef,
    Optional[String] $su = undef,
    Optional[String] $create = undef,
    Optional[String] $old_dir = undef,
) {

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
