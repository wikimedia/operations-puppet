class profile::sretest {
    if debian::codename::eq('buster') {
        include profile::docker::firewall
        include profile::base::cuminunpriv
    }

    profile::contact { $title:
        contacts => ['jbond', 'MoritzMuehlenhoff']
    }

    # Temporarily for some tests
    debian::autostart('nginx', false)
    debian::autostart('apache2', false)
}
