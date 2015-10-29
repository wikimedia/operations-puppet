class snapshot::packages {

    # pick up various users, twemproxy
    include ::mediawiki
    include mediawiki::nutcracker

    require_package('mwbzutils')
    require_package('mysql-client')
    require_package('p7zip-full')
    require_package('subversion')
    require_package('utfnormal')
    require_package('pbzip2')
}
