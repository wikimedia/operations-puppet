class apt::update {
    exec { '/usr/bin/apt-get update':
        timeout => 240,
        returns => [ 0, 100 ],
    }
}
