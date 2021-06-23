class profile::sretest {
    if debian::codename::eq('buster') {
        include profile::docker::firewall
        include profile::base::cuminunpriv
    }

    profile::logoutd::script {'sretest':
        source => 'puppet:///modules/profile/sretest/sretest-logout.py',
    }
    profile::contact { $title:
        contacts => ['jbond', 'MoritzMuehlenhoff']
    }
}
