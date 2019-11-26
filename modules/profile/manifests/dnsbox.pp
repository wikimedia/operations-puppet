# Combo profile for configuring production dnsN00x machines in a combined role
# for recursive DNS, authoritative DNS, and NTP.
class profile::dnsbox(
    Boolean $include_auth = lookup('profile::dnsbox::include_auth', {default_value => false}),
) {
    include ::profile::standard
    include ::profile::dns::recursor
    include ::profile::ntp

    # The $include_auth mechanism is temporary as we progressively test and
    # roll out this setup to the dnsbox fleet.
    if $include_auth {
        include ::profile::dns::auth
        # XXX also need to put some minimal glue here, in the form of puppet and systemd dependencies, to ensure that the recdns service requires the gdnsd service to happen first.  At the systemd layer this will probably be with add-in fragments defining the runtime relationship...
    }
}
