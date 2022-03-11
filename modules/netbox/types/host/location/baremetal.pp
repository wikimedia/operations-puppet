type Netbox::Host::Location::BareMetal = Struct[{
    # should at some point have a Wmflib::Site
    site    => String[5,5],
    row     => String[11,11],
    rack    => String[2,2],
}]
