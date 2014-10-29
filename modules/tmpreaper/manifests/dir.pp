# == Define: tmpreaper::dir
#
# Add a directory to the set of directories purged by tmpreaper's
# daily cron script.
#
# === Parameters
#
# [*ensure*]
#   'present' means that the directory will be managed by tmpreaper;
#   'absent' means it will not be. The value of this parameter does
#    not create or destroy the directory on disk.
#
# [*path*]
#   Path to tidy. Defaults to the resource name.
#
# === Example
#
#  tmpreaper::dir { '/tmp':
#    ensure => present,
#  }
#
define tmpreaper::dir(
    $ensure = present,
    $path   = $name,
) {
    include ::tmpreaper

    validate_absolute_path($path)

    $safe_name = regsubst($title, '\W', '-', 'G')
    $safe_path = regsubst($path, '/?$', '/')

    file_line { "tmpreaper_dir_${safe_name}":
        ensure  => $ensure,
        line    => "TMPREAPER_DIRS=\"\${TMPREAPER_DIRS} ${safe_path}.\"",
        path    => '/etc/tmpreaper.conf'
        require => Package['tmpreaper'],
    }
}
