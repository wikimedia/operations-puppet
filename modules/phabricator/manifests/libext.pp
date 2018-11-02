# == Define: phabricator::libext
#
# Installs phutil library extensions
#
# === Parameters
#
# [*rootdir*]
#    The path on disk to clone the needed repositories
# [*libname*]
#    Case sensitive extension name


define phabricator::libext (
    Stdlib::Unixpath $rootdir,
    String $libname = $name,
){

    # symlink static directories for extensions
    $static_dir  = "${rootdir}/libext/${libname}/rsrc/webroot-static"
    $symlink_dir = "${rootdir}/phabricator/webroot/rsrc/${libname}"

    # create the symlink, but only if the target of the link exists
    exec { "${libname}_static_dir_exists":
        command => "/bin/ln -s ${static_dir} ${symlink_dir}",
        onlyif  => "/usr/bin/test -e ${static_dir}",
        creates => $symlink_dir,
        require => File[$rootdir],
    }

}
