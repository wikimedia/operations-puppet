# Class to just install git-lfs
class git::lfs {
    if debian::codename::ge('stretch') {
        ensure_packages('git-lfs')
    }
}
