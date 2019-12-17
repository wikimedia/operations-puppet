# Given a monitoring stanza, return the data in the format we expect from
# lvs services.
function wmflib::service::lvs_icinga(Wmflib::Service::Monitoring $data) >> Hash {
    if $data['check_command'] =~ /^check_http_https\!(.*)$/ {
        {
            'uri'           => $1,
            'sites'         => $data['sites'],
            'critical'      => $data['critical'],
            'contact_group' => $data['contact_group'],
        }
    }
    else {
        $data
    }
}
