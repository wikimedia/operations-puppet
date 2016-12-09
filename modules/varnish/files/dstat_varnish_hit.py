"""
Display varnish hitrate in dstat

Usage: dstat --varnish-hit

  Copyright 2016 Emanuele Rocca <ema@wikimedia.org>

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

"""


import os


class dstat_plugin(dstat):  # noqa F821 undefined name 'dstat'
    """
    Display varnish cache miss/hit percentages in dstat
    """
    def __init__(self):
        self.name = 'hitrate'
        self.vars = ('fe-hitrate', 'be-hitrate')
        self.nick = ('fe%', 'be%')
        self.type = 'd'
        self.scale = 10

        # Initial values
        self.values = {
            'be': self.varnishstat(frontend=False),
            'fe': self.varnishstat(frontend=True),
        }

    def check(self):
        if os.system("varnishstat -1 > /dev/null") != 0:
            raise Exception('Non-zero exit code from varnishstat')

    def varnishstat(self, frontend=False):
        cmd = "varnishstat -1 -f MAIN.cache_hit -f MAIN.cache_miss"

        if frontend:
            cmd += " -n frontend"

        data = os.popen(cmd)
        total = {}
        for line in data.readlines():
            row = line.split()
            if not row:
                continue

            item = row[0].replace("MAIN.", "")
            # Use third column, change per second
            value = float(row[1])
            total[item] = value

        return total

    def hitrate(self, frontend=False):
        if frontend:
            label = "fe"
        else:
            label = "be"

        values = self.varnishstat(frontend)
        hit = values['cache_hit'] - self.values[label]['cache_hit']
        miss = values['cache_miss'] - self.values[label]['cache_miss']
        self.val[label + "-hitrate"] = 100 * (hit / (0.0001 + hit + miss))

        if frontend:
            self.values['fe'] = values
        else:
            self.values['be'] = values

    def extract(self):
        self.hitrate(frontend=False)
        self.hitrate(frontend=True)
