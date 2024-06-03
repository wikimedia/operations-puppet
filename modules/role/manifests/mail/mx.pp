class role::mail::mx {
    # tag as a public inbound mx server
    tag 'mx_in'
    include profile::base::production
    include network::constants
    include privateexim::aliases::private
    include profile::firewall
    include profile::mail::mx
}
