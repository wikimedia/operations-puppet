class snapshot::dumps(
    $enable    = true,
) {
    class { 'snapshot::dumps::configs':
        enable => $enable,
    }
    class { 'snapshot::dumps::dblists':
        enable => $enable,
    }
    class { 'snapshot::dumps::templates':
      enable => $enable,
    }
    class { 'snapshot::dumps::stagesconfig':
        enable => $enable,
    }
}
