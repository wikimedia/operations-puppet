# Class to just install git-lfs
class git::lfs {
    stdlib::ensure_packages('git-lfs')
}
