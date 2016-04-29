# coding=utf8
"Collect cherry pick count for operations/puppet"
import subprocess
import diamond.collector


class CherryPickCounterCollector(diamond.collector.Collector):
    def collect(self):
        lines = subprocess.check_output([
            '/usr/bin/sudo',
            '/usr/bin/git',
            '--git-dir=/var/lib/git/operations/puppet/.git',
            'log',
            '--pretty=oneline',
            '--abbrev-commit',
            'origin/HEAD..HEAD'
        ]).splitlines()
        self.publish('cherrypicked_commits.ops-puppet', len(lines))
