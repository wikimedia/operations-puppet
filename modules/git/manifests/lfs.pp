# Class to just install git-lfs
class git::lfs {
    if os_version('debian >= stretch') {
        require_package('git-lfs')
    }
}
