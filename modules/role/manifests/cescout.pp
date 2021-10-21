# server running the censorship monitoring tools
class role::cescout {

    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::cescout

    system::role { 'cescout':
        description => 'Censorship monitoring tools'
    }
}
