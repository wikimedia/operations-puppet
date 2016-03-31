class snapshot::addschanges(
    $enable=true,
    $user=undef,
) {
    include snapshot::dumps::dirs

    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    class { 'snapshot::addschanges::config':
        enable => $enable,
    }
    class { 'snapshot::addschanges::templates':
        enable => $enable,
    }

    cron { 'adds-changes':
        ensure      => $ensure,
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "python ${snapshot::dumps::dirs::addschangesdir}/generateincrementals.py --configfile ${snapshot::dumps::dirs::addschangesdir}/confs/addschanges.conf",
        minute      => '50',
        hour        => '23',
    }
}
