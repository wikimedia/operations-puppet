# Include this role on *any* production host that wants to
# receive gerrit replication
class role::gerrit::production::replicationdest {
    system::role { 'role::gerrit::replicationdest': description => 'Destination for gerrit replication' }

    class { 'gerrit::replicationdest':
        ssh_key => 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAxOlshfr3UaPr8gQ8UVskxHAGG9xb55xDyfqlK7vsAs/p+OXpRB4KZOxHWqI40FpHhW+rFVA0Ugk7vBK13oKCB435TJlHYTJR62qQNb2DVxi5rtvZ7DPnRRlAvdGpRft9JsoWdgsXNqRkkStbkA5cqotvVHDYAgzBnHxWPM8REokQVqil6S/yHkIGtXO5J7F6I1OvYCnG1d1GLT5nDt+ZeyacLpZAhrBlyFD6pCwDUhg4+H4O3HGwtoh5418U4cvzRgYOQQXsU2WW5nBQHE9LXVLoL6UeMYY4yMtaNw207zN6kXcMFKyTuF5qlF5whC7cmM4elhAO2snwIw4C3EyQgw== gerrit@production',
    }
}
