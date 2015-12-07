class role::torrus {
    include ::torrus
    include ::torrus::web
    include ::torrus::xml_generation::cdn
    include passwords::network
    $snmp_ro_community = $passwords::network::snmp_ro_community

    $corerouters = [
        'cr1-eqdfw.wikimedia.org',
        'cr1-eqiad.wikimedia.org',
        'cr1-eqord.wikimedia.org',
        'cr1-esams.wikimedia.org',
        'cr2-esams.wikimedia.org',
        'cr1-ulsfo.wikimedia.org',
        'cr1-ulsfo.wikimedia.org',
        'cr2-codfw.wikimedia.org',
        'cr2-eqiad.wikimedia.org',
        'cr2-knams.wikimedia.org',
        'cr2-ulsfo.wikimedia.org',
        'pfw1-codfw.wikimedia.org',
        'pfw1-eqiad.wikimedia.org',
    ]

    $accessswitches = [
        'asw2-a5-eqiad.mgmt.eqiad.wmnet',
        'asw-a-eqiad.mgmt.eqiad.wmnet',
        'asw-b-eqiad.mgmt.eqiad.wmnet',
        'asw-c-eqiad.mgmt.eqiad.wmnet',
        'asw-d-eqiad.mgmt.eqiad.wmnet',
        'asw-a-codfw.mgmt.codfw.wmnet',
        'asw-b-codfw.mgmt.codfw.wmnet',
        'asw-c-codfw.mgmt.codfw.wmnet',
        'asw-d-codfw.mgmt.codfw.wmnet',
        'asw-esams.mgmt.esams.wmnet',
        'csw2-esams.mgmt.esams.wmnet',
        'msw1-eqiad.mgmt.eqiad.wmnet',
        'psw1-eqiad.mgmt.eqiad.wmnet',
        'msw1-codfw.mgmt.codfw.wmnet',
    ]

    $storagehosts = [
        'nas1001-a.eqiad.wmnet',
        'nas1001-b.eqiad.wmnet',
    ]

    ::torrus::discovery::ddxfile { 'corerouters':
        subtree        => '/Core_routers',
        snmp_community => $snmp_ro_community,
        hosts          => $corerouters,
    }

    ::torrus::discovery::ddxfile { 'accessswitches':
        subtree        => '/Access_switches',
        snmp_community => $snmp_ro_community,
        hosts          => $accessswitches,
    }

    ::torrus::discovery::ddxfile { 'storage':
        subtree        => '/Storage',
        snmp_community => $snmp_ro_community,
        hosts          => $storagehosts,
    }

    monitoring::service { 'torrus-http':
        description   => 'torrus.wikimedia.org HTTP',
        check_command => 'check_https_url_for_string!torrus.wikimedia.org!/torrus!\'Torrus Top: Wikimedia\'',
    }
}
