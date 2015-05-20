class ssh::hostkeys-collect {
    # Do this about twice a day
    $potm = inline_template('<%= srand ; (rand(25) == 5).to_s.capitalize -%>')
    if $hostname == "tin" or $hostname == "bast1001" or $hostname == "mira" or $potm == "True" {
        notice("Collecting SSH host keys on ${hostname}.")

        # install all collected SSH host keys
        Sshkey <<| |>>

        # clean up unmanaged host keys
        resources { 'sshkey':
            purge => true,
        }
    }
}
