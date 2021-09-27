# @summary Takes a directory or list of directories and returns a normalised version.
#
# Currently all this means is that we ensure all directories have the trailing slash removed
# Further we ensure strings are converted to one element arrays
#
# @param dirs either an absolute path or a array of absolute paths.
# @return an array of absolute paths after being normalised
# @example calling the function
#  wmflib::dir::normalise('/opt/puppetlabs/') => ['/opt/puppetlabs']
#  wmflib::dir::normalise('/opt/puppetlabs') => ['/opt/puppetlabs']
#  wmflib::dir::normalise(['/opt/puppetlabs', '/tmp/']) => ['/opt/puppetlabs', '/tmp']
function wmflib::dir::normalise(
    Variant[Stdlib::Unixpath, Array[Stdlib::Unixpath]] $dirs
) >> Array[Stdlib::Unixpath] {
    [$dirs].flatten.unique.map |$dir| {
        # special case for root dir
        if $dir == '/' {
            $dir
        } elsif $dir.stdlib::end_with('/') {
            $dir[0,-2]
        } else {
            $dir
        }

    }.flatten.unique
}
