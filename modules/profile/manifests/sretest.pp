class profile::sretest {
    if debian::codename::eq('buster') {
        include profile::docker::firewall
        include profile::base::cuminunpriv
    }

    profile::contact { $title:
        contacts => ['jbond', 'jmm']
    }

}
