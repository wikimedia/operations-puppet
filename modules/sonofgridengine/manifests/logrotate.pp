# == Class: sonofgridengine::logrotate
#
# == Parameters
#
# [*sge_root*]
#   Default: /data/project/.system_sge/gridengine
#
# [*sge_cell*]
#   Default: default
#
class sonofgridengine::logrotate (
    $sge_root = '/data/project/.system_sge/gridengine',
    $sge_cell = 'default',
    $ensure   = 'present',
) {

    logrotate::conf { 'sge':
        ensure  => $ensure,
        content => template('sonofgridengine/logrotate.erb'),
    }
}
