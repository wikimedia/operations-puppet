class wmrole::gerrit::production {
    system_role { "role::gerrit::production": description => "Gerrit master" }

    class { "gerrit::instance":
        ircbot => true,
        db_host => "db1048.eqiad.wmnet",
        host => "gerrit.wikimedia.org",
        ssh_key => "AAAAB3NzaC1yc2EAAAABIwAAAQEAxOlshfr3UaPr8gQ8UVskxHAGG9xb55xDyfqlK7vsAs/p+OXpRB4KZOxHWqI40FpHhW+rFVA0Ugk7vBK13oKCB435TJlHYTJR62qQNb2DVxi5rtvZ7DPnRRlAvdGpRft9JsoWdgsXNqRkkStbkA5cqotvVHDYAgzBnHxWPM8REokQVqil6S/yHkIGtXO5J7F6I1OvYCnG1d1GLT5nDt+ZeyacLpZAhrBlyFD6pCwDUhg4+H4O3HGwtoh5418U4cvzRgYOQQXsU2WW5nBQHE9LXVLoL6UeMYY4yMtaNw207zN6kXcMFKyTuF5qlF5whC7cmM4elhAO2snwIw4C3EyQgw==",
        ssl_cert => "gerrit.wikimedia.org",
        ssl_cert_key => "gerrit.wikimedia.org",
        replication => {
            # If adding a new entry, remember to add the fingerprint to gerrit2's known_hosts
            "inside-wmf" => {
              "url" => 'gerritslave@gallium.wikimedia.org:/var/lib/git/${name}.git',
              "threads" => "4",
              "mirror" => "true",
            },
            "gitblit" => {
                "url" => 'gerritslave@antimony.wikimedia.org:/var/lib/git/${name}.git',
                "threads" => "4",
                "authGroup" => "mediawiki-replication",
                "push" => "refs/*:refs/*",
                "mirror" => "true",
            },
            "github" => {
              "url" => 'git@github.com:wikimedia/${name}',
              "threads" => "4",
              "authGroup" => "mediawiki-replication",
              "push" => "+refs/heads/*:refs/heads/*
  push = +refs/tags/*:refs/tags/*",
              "remoteNameStyle" => "dash",
              "mirror" => "true",
            },
        },
        smtp_host => "smtp.pmtpa.wmnet"
    }
}

# Include this role on *any* production host that wants to
# receive gerrit replication
class wmrole::gerrit::production::replicationdest {
    system_role { "role::gerrit::replicationdest": description => "Destination for gerrit replication" }

    class { "gerrit::replicationdest":
        sshkey => "AAAAB3NzaC1yc2EAAAABIwAAAQEAxOlshfr3UaPr8gQ8UVskxHAGG9xb55xDyfqlK7vsAs/p+OXpRB4KZOxHWqI40FpHhW+rFVA0Ugk7vBK13oKCB435TJlHYTJR62qQNb2DVxi5rtvZ7DPnRRlAvdGpRft9JsoWdgsXNqRkkStbkA5cqotvVHDYAgzBnHxWPM8REokQVqil6S/yHkIGtXO5J7F6I1OvYCnG1d1GLT5nDt+ZeyacLpZAhrBlyFD6pCwDUhg4+H4O3HGwtoh5418U4cvzRgYOQQXsU2WW5nBQHE9LXVLoL6UeMYY4yMtaNw207zN6kXcMFKyTuF5qlF5whC7cmM4elhAO2snwIw4C3EyQgw=="
    }
}
