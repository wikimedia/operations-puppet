# == Class role::eventlogging::analytics
#
class role::eventlogging::analytics {
    eventlogging::plugin { 'plugins':
        source => 'puppet:///modules/eventlogging/plugins.py',
    }
}
