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
    $wgetreject = "--reject-regex '(.*)\?(.*)'"
    $wgetargs = "-nv -e robots=off -k -nH --wait 30 -np -m ${url} -P ${wikitechdir}"

    # the index.html files we get from wikitech are icky,
    # best to toss them when done
    $cleanuphtml = "find ${wikitechdir} -name 'index.html*' -exec rm {} \\;"
    $cleanupold = "find ${wikitechdir} -type f -mtime +90 -exec rm {} \\;"

    cron { 'wikitech-dumps-grab':
        ensure  => $ensure,
        command => "${wget} ${wgetreject} ${wgetargs}; ${cleanuphtml}; ${cleanupold}",
        user    => $user,
        minute  => '20',
        hour    => '3',
    }
}
