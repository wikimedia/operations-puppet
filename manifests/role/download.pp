# role classes for download servers

# common classes included by all download servers
class role::download::common {

    include standard,
            admins::roots,
            groups::wikidev,
            accounts::catrope
}

# download.wikimedia.org
class role::download::wikimedia {
    include role::download::common
    include ::download::wikimedia
}

# download.mediawiki.org
class role::download::mediawiki {
    include role::download::common
    include ::download::mediawiki
}
