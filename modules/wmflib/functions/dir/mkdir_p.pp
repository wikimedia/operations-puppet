# @summary Like the unix command `mkdir -p` except with puppet code.
# This creates file resources for all directories returned by wmflib::dir::split.  you can also
# pass a parameteres hash of file resource paramters which will be applied to the target dirs
#
# @param dirs  the path(s) to create
# @param params the resource parameters to apply to dirs
# @example creating directories
#  wmflib::dir::mkdir_p('/opt/puppetlabs/bin') will create:
#  file{['/opt', '/opt/puppetlabs', '/opt/puppetlabs/bin']: ensure => directory}
# @example creating directories with additional properties
#  wmflib::dir::mkdir_p('/opt/puppetlabs/bin', {owner => 'foobar'}) will create:
#  file{['/opt', '/opt/puppetlabs']: ensure => directory}
#  file{['/opt', '/opt/puppetlabs']:
#    ensure => directory,
#	 owner  => 'foobar',
#  }
function wmflib::dir::mkdir_p(
    Variant[Stdlib::Unixpath, Array[Stdlib::Unixpath]] $dirs,
    Hash                                               $params = {},
) {
    # FHS dirs generated via:
    # $ MANWIDTH=100 man file-hierarchy |
    #   sed -e 's/\/, /\n       /g' -e 's/arch-id/x86_64-linux-gnu/' |
    #   grep '^       /.*/$' |
    #   sed -Ee "s/ *(.*)\/$/        '\1',/g" |
    #   sort -u
    $fhs_dirs = [
        '/boot',
        '/dev',
        '/dev/shm',
        '/efi',
        '/etc',
        '/home',
        '/lib',
        '/lib64',
        '/lib/x86_64-linux-gnu',
        '/proc',
        '/proc/sys',
        '/root',
        '/run',
        '/run/log',
        '/run/user',
        '/srv',
        '/sys',
        '/sys/fs/cgroup',
        '/tmp',
        '/usr',
        '/usr/bin',
        '/usr/include',
        '/usr/lib',
        '/usr/sbin',
        '/usr/share',
        '/usr/share/doc',
        '/usr/share/factory/etc',
        '/usr/share/factory/var',
        '/var',
        '/var/cache',
        '/var/lib',
        '/var/log',
        '/var/run',
        '/var/spool',
        '/var/tmp',
    ]

    $_dirs = wmflib::dir::normalise($dirs)
    # Exclude FHS dirs as they are known to exist
    $parents = wmflib::dir::split($_dirs) - $_dirs - $fhs_dirs
    # ensure all parent directories exist
    ensure_resource('file', $parents, {'ensure' => 'directory'})
    # Apply params only to the actual directories
    ensure_resource('file', $dirs, {'ensure'    => 'directory'} + $params)
}

