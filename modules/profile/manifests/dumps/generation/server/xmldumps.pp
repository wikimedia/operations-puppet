class profile::dumps::generation::server::xmldumps(
    $dumps_single_backend = lookup('profile::dumps::single_backend'),
    $internals = lookup('profile::dumps::internal'),
    $publics = lookup('profile::dumps::public'),
    $xmldumpsdir = lookup('profile::dumps::xmldumpsdir'),
) {
    require profile::dumps::generation::server::common

    if (!$dumps_single_backend) {

        $internaldests = $internals.map |$i| {"${i}::data/xmldatadumps/public/"}.join(',')
        $xmlpublicdests = $publics.map |$p| {"${p}::data/xmldatadumps/public/"}.join(',')

        class { '::dumps::generation::server::rsyncer_xml':
            xmldumpsdir   => $xmldumpsdir,
            xmlremotedirs => "${internaldests},${xmlpublicdests}",
        }
    }

    nrpe::monitor_service { 'dumps_store_load_average':
        description  => 'high load average on dumps nfs store',
        nrpe_command => '/usr/lib/nagios/plugins/check_load -w 30,20,10 -c 100,80,50',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Dumps/XML-SQL_Dumps#Troubleshooting',
    }
}
