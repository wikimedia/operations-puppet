class dataset::cron::wikitech_dumps(
    $enable = true,
    $user   = root,
    $url    = undef,
) {

    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    include dataset::dirs

    $wikitechdir = "${dataset::dirs::otherdir}/wikitech"

    file { $wikitechdir:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    $wget = '/usr/bin/wget'
    $wgetargs = "-e robots=off -k -nH --wait 30 -np -m ${url} -P ${wikitechdir}"

    # the index.html files we get from wikitech are icky,
    # best to toss them when done
    $cleanup = "rm ${wikitechdir}/index.html*"

    cron { 'wikitech-dumps-grab':
        ensure  => $ensure,
        command => "${wget} ${wgetargs}; ${cleanup}",
        user    => $user,
        minute  => '20',
        hour    => '3',
    }
}
