class snapshot::dumps::stagesconfig(
    $enable = true,
) {

    include snapshot::dirs

    $firststage_args = '--cutoff today'
    $rest_args= '--date last --onepass'
    $wikiargs = '/bin/bash ./worker --skipdone --exclusive --log'

    $args_smallwikis = "${wikiargs} --configfile confs/wikidump.conf"
    $args_bigwikis = "${wikiargs} --configfile confs/wikidump.conf.bigwikis"
    $args_hugewikis = "${wikiargs} --configfile confs/wikidump.conf.hugewikis"

    $jobs_to_skip = join(['metahistorybz2dump',
                          'metahistorybz2dumprecombine',
                          'metahistory7zdump',
                          'metahistory7zdumprecombine'], ',')

    $stages = {
        smallwikis   => {
            firststage => "${args_smallwikis} ${firststage_args}",
            rest       => "${args_smallwikis} ${rest_args}",
        },
        bigwikis     => {
            firststage => "${args_bigwikis} ${firststage_args}",
            rest       => "${args_bigwikis} ${rest_args}",
        },
        hugewikis    => {
            firststage => "${args_hugewikis} ${firststage_args}",
            rest       => "${args_hugewikis} ${rest_args}",
        },
        skipjob_args => "--skipjobs ${jobs_to_skip}",
    }

    if ($enable) {
        file { "${snapshot::dirs::dumpsdir}/stages":
            ensure => 'directory',
            path   => "${snapshot::dirs::dumpsdir}/stages",
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
        }
        file { "${snapshot::dirs::dumpsdir}/cache":
            ensure => 'directory',
            path   => "${snapshot::dirs::dumpsdir}/cache",
            mode   => '0755',
            owner  => 'datasets',
            group  => 'root',
        }

        snapshot::dumps::stagesconf { 'stages_normal':
            stagestype => 'normal',
            stages     => $stages,
        }
        snapshot::dumps::stagesconf { 'stages_partial':
            stagestype => 'partial',
            stages     => $stages,
        }
        snapshot::dumps::stagesconf { 'stages_normal_nocreate':
            stagestype => 'normal_nocreate',
            stages     => $stages,
        }
        snapshot::dumps::stagesconf { 'stages_partial_nocreate':
            stagestype => 'partial_nocreate',
            stages     => $stages,
        }
        snapshot::dumps::stagesconf { 'stages_normal_hugewikis':
            stagestype => 'normal_huge',
            stages     => $stages,
        }
        snapshot::dumps::stagesconf { 'stages_partial_hugewikis':
            stagestype => 'partial_huge',
            stages     => $stages,
        }
        snapshot::dumps::stagesconf { 'stages_create':
            stagestype => 'create',
            stages     => $stages,
        }
        snapshot::dumps::stagesconf { 'stages_create_huge':
            stagestype => 'create_huge',
            stages     => $stages,
        }
    }
}
