class ssh::hostkeys-collect {
    # Do this about twice a day
    $potm = inline_template('<%= srand ; (rand(25) == 5).to_s.capitalize -%>')
    if $hostname == "fenari" or $hostname == "tin" or $hostname == "bast1001" or $potm == "True" {
        notice("Collecting SSH host keys on $hostname.")

    # Install all collected ssh host keys
        Ssh::Hostkey <<| |>>
    }
}
