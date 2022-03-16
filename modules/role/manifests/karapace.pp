# karapace instance
#
class role::karapace {

    system::role { 'karapace':
        description => 'Karapace schema registry for kafka'
    }

    include profile::base::production
    include profile::base::firewall
    include profile::karapace::main
}
