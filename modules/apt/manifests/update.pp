class apt::update {
	exec { '/usr/bin/apt-get update':
		timeout => 240,
		returns => [ 0, 100 ];
	}
}

class apt::updatefornewrepo {
    exec { 'update-for-new-repo':
		command => '/usr/bin/apt-get update',
        timeout => 240,
        returns => [ 0, 100 ];
    }
}

Apt::Repository <| |> -> Class['apt::updatefornewrepo']
