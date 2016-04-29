# coding=utf8
"Collect cherry pick count for operations/puppet and labs/private"
import subprocess
import os
import diamond.collector


class CherryPickCounterCollector(diamond.collector.Collector):
    def collect(self):
        for repository in ['operations/puppet', 'labs/private']:
            os.environ['PWD'] = '/var/lib/git/' + repository
            lines = subprocess.check_output([
                '/usr/bin/sudo',
                'git log --pretty=oneline --abbrev-commit origin/HEAD..HEAD'
            ]).splitlines()
            self.publish('cherrypicked_commits.' + repository, len(lines))
