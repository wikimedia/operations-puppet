# == Class statistics::geowiki
# Clones analytics/geowiki python scripts
class statistics::geowiki {
    require statistics

    $geowiki_user           = $statistics::username
    $geowiki_base_path      = '/a/geowiki'
    $geowiki_scripts_path   = "${geowiki_base_path}/scripts"
    $private_data_bare_path = "${geowiki_base_path}/data-private-bare"

    git::clone { 'geowiki-scripts':
        ensure    => 'latest',
        directory => $geowiki_scripts_path,
        origin    => 'https://gerrit.wikimedia.org/r/p/analytics/geowiki.git',
        owner     => $geowiki_user,
        group     => $geowiki_user,
    }
}

