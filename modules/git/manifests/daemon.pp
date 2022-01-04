# Definition: git::daemon
#
# Runs a read-only git-daemon process, exporting all repos, or just
# those specified by the 'directories' parameter.
#
# === Optional parameters
#
# $base_path: If specified, remap all the path requests as relative to
#   the given path. This is sort of "Git root" - if you run git daemon
#   with $base_path=/srv/git on example.com, then if you later try to
#   pull git://example.com/hello.git, git daemon will interpret the path
#   as /srv/git/hello.git.
#
# $directories: An array of directories to export.  If not supplied, then
#   all directories are exported.
#
# $user/$group: The user and group to run git-daemon as.
#
# $max_connections: The maximum number of simultaneous connections to allow.

class git::daemon(
    Optional[Stdlib::Unixpath] $base_path = undef,
    Array[Stdlib::Unixpath] $directories = [],
    String $user = 'nobody',
    String $group = 'nobody',
    Integer $max_connections = 32,
) {
    # We dont want to honor `git send-pack` commands so make sure the
    # receive-pack service is always disabled.
    $daemon_options = "--export-all --forbid-override=receive-pack --max-connections=${max_connections}"

    systemd::service { 'git-daemon':
        ensure  => present,
        content => systemd_template('git-daemon'),
        restart => true,
    }

    systemd::syslog { 'git-daemon':
        owner       => $user,
        group       => $group,
        readable_by => 'all',
    }

}
