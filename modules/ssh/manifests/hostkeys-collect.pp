class ssh::hostkeys-collect {
    # Do this about twice a day
    if generate('/usr/local/bin/position-of-the-moon') == 'True' {
        notice("Collecting SSH host keys on ${::hostname}.")

    # Install all collected ssh host keys
        ssh::Hostkey <<| |>>
    }
}
