# = Class: contint::monitoring::graphite
# Sets up graphite based icinga checks for all of integration
class contint::monitoring::graphite {
    monitoring::graphite_threshold { 'contint-cpu-iowait':
        description   => 'CI: Excess CPU check: iowait',
        metric        => 'integration.*.cpu.total.iowait.value',
        warning       => 90,
        critical      => 97,
        percentage    => 100,
        graphite_url  => 'http://labmon1001.eqiad.wmnet',
        contact_group => 'contint',
        series        => true,
    }

    monitoring::graphite_threshold { 'contint-cpu-user':
        description   => 'CI: Excess CPU check: user',
        metric        => 'integration.*.cpu.total.user.value',
        warning       => 90,
        critical      => 97,
        percentage    => 100,
        graphite_url  => 'http://labmon1001.eqiad.wmnet',
        contact_group => 'contint',
        series        => true,
    }

    monitoring::graphite_threshold { 'contint-cpu-system':
        description   => 'CI: Excess CPU check: system',
        metric        => 'integration.*.cpu.total.system.value',
        warning       => 90,
        critical      => 97,
        percentage    => 100,
        graphite_url  => 'http://labmon1001.eqiad.wmnet',
        contact_group => 'contint',
        series        => true,
    }
}
