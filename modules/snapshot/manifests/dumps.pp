class snapshot::dumps(
    $enable    = true,
    $hugewikis = false,
) {
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
