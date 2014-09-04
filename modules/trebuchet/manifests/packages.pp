# == Class: trebuchet::packages
#
# Provision packages required for trebuchet to operate
#
class trebuchet::packages {
    include stdlib

    # Installs git-core
    require base::standard-packages

    #git-fat was not in hardy
    if ubuntu_version('> hardy') {
        ensure_packages(['git-fat'])
    }


    ensure_packages(['python-redis'])
}
