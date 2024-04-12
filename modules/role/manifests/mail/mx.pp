class role::mail::mx {
    include profile::base::production
    include network::constants
    include privateexim::aliases::private
    include profile::firewall
    include profile::mail::mx
}
