# url\_downloader Puppet Module #

A Puppet module for installing and configuring a forward proxy used to fetch URLs

## Requirements ##
- An Ubuntu distro

## Notes ##

A public IP is required to use this module. It is the IP on which the squid
proxy will listen on and the one used to initiate connections fetching URLs

## Usage ##
### Configure your url\_downloader ###

	class { '::url_downloader':
		service_ip => '10.10.10.10' # But please choose a public IP
	}
