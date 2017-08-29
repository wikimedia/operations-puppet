class profile::dumpsdata::primary(
    $dumps_webservers = hiera('dumps_webservers'),
    $dumpsdata_secondaries =hiera('dumpsdata_secondary_hosts')
) {
    require ::profile::dumpsdata::base

    class { '::dumpscopy':
        user  => $dumpsuser::user,
        source => $dumpsdirs::publicdir,
        dest => join(concat($dumps_webservers,$dumpsdata_secondaries),","),
}
