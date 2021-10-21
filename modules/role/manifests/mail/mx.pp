# filtertags: labs-project-deployment-prep
class role::mail::mx {
    include profile::base::production
    include network::constants
    include privateexim::aliases::private
    include profile::base::firewall
    include profile::mail::mx

    system::role { 'mail::mx':
        description => 'Mail router',
    }
}
