# == Define: tmpreaper::reap
#
# Purge a directory hierarchy of files that have not been accessed in
# a given period of time. Like `puppet::tidy`, but fast and secure.
#
# === Parameters
#
# [*path*]
#   Path to tidy. Defaults to the resource name.
#
# [*age*]
#   Defines the age threshold for removing files. If the file has not been
#   accessed for <$age>, it becomes eligible for removal. The value should
#   be a number suffixed by one character: 'd' for days, 'h' for hours, 'm'
#   for minutes, or 's' for seconds. Defaults to '7d'.
#
# [*include_symlinks*]
#   If true, remove symlinks too, not just regular files and directories.
#   False by default.
#
# [*include_all*]
#   If true, remove all file types, not just regular files, symlinks, and
#   directories. Defaults to false.
#
# [*protect*]
#   An optional array of shell patterns specifying files that should be
#   protected from deletion.
#
# === Example
#
#  tmpreaper::reap { '/tmp':
#      age              => '1d',
#      protect          => ['*.log'],
#      include_symlinks => true,
#  }
#
define tmpreaper::reap(
    $path             = $name,
    $age              = '7d',
    $protect          = [],
    $include_symlinks = false,
    $include_all      = false,
) {
    include ::tmpreaper

    validate_re($age, '^\d+[smhd]$')
    validate_absolute_path($path)

    $args = template('tmpreaper/args.erb')

    exec { "/usr/sbin/tmpreaper ${args}":
        onlyif   => "/usr/sbin/tmpreaper --test ${args} 2>&1 | /bin/grep -q remove",
        require  => Package['tmpreaper'],
    }
}
