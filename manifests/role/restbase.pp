# == Class role::restbase
#

# Config should be pulled from hiera
class role::restbase {
    system::role { 'restbase': description => "Restbase ${::realm}" }

    include ::restbase
}

# Not needed, just to keep whatever is live working, feel free to remove this
class role::restbase::labs {
    require role::restbase
}
