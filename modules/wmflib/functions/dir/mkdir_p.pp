# @summary Like the unix command `mkdir -p` except with puppet code.
# This creates file resources for all directories returned by wmflib::dir::split.  you can also
# pass a parameteres hash of file resource paramters which will be applied to the target dirs
#
# @param dirs  the path(s) to create
# @param params the resource parameters to apply to dirs
# @example creating directories
#  extlib::mkdir_p('/opt/puppetlabs/bin') will create:
#  file{['/opt', '/opt/puppetlabs', '/opt/puppetlabs/bin']: ensure => directory}
# @example creating directories with additional properties
#  extlib::mkdir_p('/opt/puppetlabs/bin', {owner => 'foobar'}) will create:
#  file{['/opt', '/opt/puppetlabs']: ensure => directory}
#  file{['/opt', '/opt/puppetlabs']:
#    ensure => directory,
#	 owner  => 'foobar',
#  }
function wmflib::dir::mkdir_p(
    Variant[Stdlib::Unixpath, Array[Stdlib::Unixpath]] $dirs,
    Hash                                               $params = {},
) {
    $all_dirs = wmflib::dir::split($dirs)
    # ensure all parent directories exist
    @file{$all_dirs:
        ensure => directory,
    }
    # Apply params only to the actual directories
    [$dirs].flatten.unique.each |$dir| {
        File[$dir] {
            * => $params,
        }
    }
    realize(File[$all_dirs])
}

