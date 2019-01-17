# == Define: eventlogging::plugin
#
# EventLogging plug-ins are Python scripts which register themselves as
# handlers for a particular URI scheme, like 'mysql://' or 'file://'.
# Upon initialization, EventLogging services traverse the plug-in directory
# and auto-load any plug-ins they encounter. The services will automatically
# delegate a stream URI to the plug-in if its scheme matches the one
# registered by the plug-in.
#
# By default, the plug-in directory is </usr/local/lib/eventlogging>,
# but another path may be configured by setting EVENTLOGGING_PLUGIN_DIR
# in the environment.
#
# === Parameters
#
# [*ensure*]
#   If 'present' (the default), ensures the plug-in file is in place.
#   If 'absent', ensures the file is removed.
#
# [*source*]
#   Specifies the file that contains the plug-in code. May be a URI or a
#   path to a local file. Either this or 'content' (but not both) must
#   be set.
#
# [*content*]
#   The desired contents of the plug-in file, as a string. Either this
#   or 'source' (but not both) must be set.
#
# === Examples
#
#  eventlogging::plugin { 'hadoop':
#    source => 'puppet:///modules/eventlogging/hadoop.py',
#  }
#
define eventlogging::plugin(
    $ensure  = present,
    $source  = undef,
    $content = undef,
) {
    $pathsafe = regsubst($title, '\W', '-', 'G')
    $basename = regsubst($pathsafe, '\.py$', '', 'I')

    file { "/usr/local/lib/eventlogging/${basename}.py":
        ensure  => $ensure,
        content => $content,
        source  => $source,
        require => File['/usr/local/lib/eventlogging'],
    }
}
