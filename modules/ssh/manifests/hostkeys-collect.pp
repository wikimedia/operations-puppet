class ssh::hostkeys-collect {

    if $hostname =~ /^(fenari)|(tin)|(bast1001)|(deployment-bastion)$/ {
        $potm = "True"
    } else {
        # Do this about twice a day
        $potm = inline_template('<%= srand ; (rand(25) == 5).to_s.capitalize -%>')
    }

    if $potm == "True" {
        notice("Collecting SSH host keys on $hostname.")
        # Install all collected ssh host keys
        Ssh::Hostkey <<| |>>
    }
}
