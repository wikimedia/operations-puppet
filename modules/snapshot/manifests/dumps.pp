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

    if ($hugewikis) {
        system::role { 'snapshot::dumps':
            ensure      => $ensure,
            description => 'producer of xml dumps for enwiki'
        }
    }
    else {
        system::role { 'snapshot::dumps':
            ensure      => $ensure,
            description => 'producer of xml dumps for all wikis but enwiki'
        }
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
}
