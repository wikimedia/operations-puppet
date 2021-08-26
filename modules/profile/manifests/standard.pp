class profile::standard {
    include profile::base
    if $::realm == 'production' {
        include profile::base::production
    }
}
