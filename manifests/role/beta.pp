# vim: set sw=4 ts=4 expandtab:

class role::beta::bastion {
    system::role { 'role::beta::bastion':
        description => 'Bastion and work machine for beta cluster'
    }

    class { 'misc::maintenance::geodata': enabled => true }

    include beta::autoupdater
    include beta::syncsiteresources

    # Bring scap related scripts such as mw-update-l10n
    include misc::deployment::scap_scripts

    # Disable fatalmonitor on eqiad beta cluster to avoid duplicate emails.
    # FIXME remove condition once beta cluster has been migrated.
    if $::site == 'pmtpa' {
        include beta::fatalmonitor
    }
}

# Should be applied on any instance that needs to access DNS entries pointing
# back to the beta cluster. This should be applied at a minimum on any instance
# running MediaWiki.
#
# WARNING: this will enable firewall (managed by ferm) with a default DROP policy
class role::beta::natfix {
    system::role { 'role::beta::natfix':
        description => 'Server has beta NAT fixup'
    }

    include beta::natfix
}
