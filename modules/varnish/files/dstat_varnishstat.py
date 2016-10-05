"""
Display varnish statistics in dstat

Usage: dstat --varnishstat

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

    def __init__(self):
        self.name = 'varnishstat'
        self.vars = ('fe-n_object', 'fe-n_lru_nuked', 'fe-backend_fail',
                     'be-n_object', 'be-n_lru_nuked', 'be-backend_fail',
                     'fe-threads', 'fe-threads_created', 'be-threads',
                     'be-threads_created')
        self.nick = ('f_nobj', 'f_nlru', 'f_bfail', 'b_nobj', 'b_nlru',
                     'b_bfail', 'f_thr', 'f_thc', 'b_thr', 'b_thc')
        self.type = 'd'
        #self.width = 6
        #self.scale = 10

    def check(self):
        if os.system("varnishstat -1 > /dev/null") != 0:
            raise Exception('Non-zero exit code from varnishstat')

    def version(self):
        cmd = os.popen("""varnishstat -V 2>&1 |
                          awk 'NR==1 { print $2 }' |
                          tr -d '('
                       """)
        return cmd.readline().rstrip()

    def varnishstat(self, frontend=False):
        if "varnish-4" in self.version():
            cmd = """varnishstat -1 -f MAIN.n_object -f MAIN.n_lru_nuked \
                     -f MAIN.backend_fail -f MAIN.threads \
                     -f MAIN.threads_created"""
        else:
            cmd = """varnishstat -1 -f n_object -f n_lru_nuked \
                     -f backend_fail -f n_wrk -f n_wrk_create"""

        if frontend:
            cmd += " -n frontend"
            label = "fe"
        else:
            label = "be"

        data = os.popen(cmd)
        total = {}
        for line in data.readlines():
            row = line.split()
            if not row:
                continue

            item = "%s-%s" % (label, row[0].replace("MAIN.", ""))
            value = float(row[1])
            total[item] = value

        if "varnish-3" in self.version():
            total["fe-threads_created"] = total.get("fe-n_wrk_create", 0)
            total["be-threads_created"] = total.get("be-n_wrk_create", 0)
            total["fe-threads"] = total.get("fe-n_wrk", 0)
            total["be-threads"] = total.get("be-n_wrk", 0)

        return total

    def extract(self):
        fields = ('n_object', 'n_lru_nuked', 'backend_fail', 'threads',
                  'threads_created')
        be_values = self.varnishstat(frontend=False)

        fe_values = self.varnishstat(frontend=True)

        for field in fields:
            self.val["fe-" + field] = fe_values.get("fe-" + field, 0)
            self.val["be-" + field] = be_values.get("be-" + field, 0)
