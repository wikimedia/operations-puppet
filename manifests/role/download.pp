# role classes for download servers

# download.wikimedia.org
class role::download::wikimedia {
    include ::download::wikimedia
}

# download.mediawiki.org
class role::download::mediawiki {
    include ::download::mediawiki
}
