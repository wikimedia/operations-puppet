# @summary Splits the given directory or directories into individual paths.
#
# Use this function when you need to split a absolute path into multiple absolute paths
# that all descend from the given path.
#
# @param dirs either an absolute path or a array of absolute paths.
# @return an array of absolute paths after being cut into individual paths.
# @example calling the function
#  wmflib::dir::split('/opt/puppetlabs') => ['/opt', '/opt/puppetlabs']
function wmflib::dir::split(
    Variant[Stdlib::Unixpath, Array[Stdlib::Unixpath]] $dirs
) >> Array[Stdlib::Unixpath] {
    [$dirs].flatten.unique.map |$dir| {
        $dir.split('/').reduce([]) |$memo, $value| {
            $value.empty ? {
                true    => $memo,
                default => $memo + "${memo[-1]}/${value}",
            }
        }
    }.flatten.unique
}
