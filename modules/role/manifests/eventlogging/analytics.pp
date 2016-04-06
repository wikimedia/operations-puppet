# == Class role::eventlogging::analytics
#
class role::eventlogging::analytics {
    system::role { 'role::eventlogging::analytics':
        description => 'EventLogging Analytics Processor and Consumer',
    }

    eventlogging::deployment::target { 'analytics':
        # TODO: Do we need this sudo rule for 'eventlogging' user here?
        # Allow eventlogging user to run eventloggingctl as root.
        # sudo_rules => ['ALL=(root) NOPASSWD: /sbin/eventloggingctl *']
    }

    # TODO: Move manifests/role/eventlogging.pp classes here.
}
