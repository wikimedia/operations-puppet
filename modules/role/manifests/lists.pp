# sets up a mailing list server
class role::lists {
    include profile::base::production
    include profile::backup::host
    include profile::firewall

    include profile::lists
    include profile::locales::extended
}
