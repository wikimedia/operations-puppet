# === Define logrotate::conf
#
# Thin helper for the definition of logrotate rules.
# It basically ensure consistency and that we don't risk things like
# https://phabricator.wikimedia.org/T127025 to happen again
#
define logrotate::conf (
    $ensure = present,
    $source = undef,
    $content = undef,
    $file_pattern = undef,
    $not_if_empty = false,
    $max_age = undef,
    $rotate = undef,
    $date_ext = false,
    $compress = false,
    $delay_compress = false,
    $missing_ok = false,
    $size = undef,
) {

    if $source or $content {
        $real_content = $content
    } else {
        if $file_pattern == undef {
            fail('$file_pattern needs to be defined when using default template')
        }
        $real_content = template('logrotate/logrotate.erb')
    }

    file { "/etc/logrotate.d/${title}":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => $source,
        content => $real_content,
    }
}
