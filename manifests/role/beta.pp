# vim: set sw=4 ts=4 expandtab:

class role::beta::bastion {
    system::role { 'role::beta::bastion':
        description => 'Bastion and work machine for beta cluster'
    }

    include beta::autoupdater
    include beta::fatalmonitor
    include beta::syncsiteresources

    # Bring scap related scripts such as mw-update-l10n
    include ::beta::scap::master

}

# To be applied on deployment-upload.eqiad.wmflabs
# Queried by Varnish upload cache whenever we need to serve thumbnails
# There is a hacked nginx on it and a php5 cgi service
class role::beta::uploadservice {

    system::role { 'role::beta::uploadservice':
        description => 'Upload/thumbs backend used by Varnish'
    }

    ferm::rule { 'allow_http':
        rule => 'proto tcp dport http ACCEPT;'
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

    include ::beta::natfix
}

# Class: role::beta::rsync_slave
#
# Provision an rsync slave server for scap in beta
#
class role::beta::rsync_slave {
    include labs_lvm

    labs_lvm::volume { 'second-local-disk':
        mountat => '/srv',
    }

    # FIXME: Each host that has this role applied must also be
    # manually added to the dsh group file found in
    # modules/beta/files/dsh/group/mediawiki-installation or scap will
    # not communicate with that host.
    class { '::beta::scap::rsync_slave':
        require => Labs_lvm::Volume['second-local-disk'],
    }
}
