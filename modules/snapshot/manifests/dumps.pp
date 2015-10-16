class snapshot::dumps(
    $enable    = true,
    $hugewikis = false,
) {

    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    class { 'snapshot::dumps::configs':
        enable           => $enable,
        hugewikis_enable => $hugewikis,
    }
    class { 'snapshot::dumps::dblists':
        enable           => $enable,
        hugewikis_enable => $hugewikis,
    }
    class { 'snapshot::dumps::templates':
        enable => 'enable'
    }
    class { 'snapshot::dumps::stagesconfig':
        enable => 'enable'
    }
}
