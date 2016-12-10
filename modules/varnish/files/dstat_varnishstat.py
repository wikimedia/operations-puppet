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

    COUNTERS = (
        ("fe-n_object", "f_nobj"),
        ("fe-n_lru_nuked", "f_nlru"),
        ("fe-backend_fail", "f_bfail"),
        ("be-n_object", "b_nobj"),
        ("be-n_lru_nuked", "b_nlru"),
        ("be-backend_fail", "b_bfail"),
        ("fe-threads", "f_thr"),
        ("fe-threads_created", "f_thc"),
        ("be-threads", "b_thr"),
        ("be-threads_created", "b_thc"),
        ("fe-exp-lag", "f_exlag"),
        ("be-exp-lag", "b_exlag"),
    )

    def __init__(self):
        self.name = "varnishstat"
        self.vars = [i[0] for i in self.COUNTERS]
        self.nick = [i[1] for i in self.COUNTERS]
        self.type = "d"

    def check(self):
        if os.system("varnishstat -1 > /dev/null") != 0:
            raise Exception("Non-zero exit code from varnishstat")

    def varnishstat(self, frontend=False):
        cmd = ("varnishstat -1 -f MAIN.n_object -f MAIN.n_lru_nuked "
               "-f MAIN.backend_fail -f MAIN.threads "
               "-f MAIN.threads_created "
               "-f MAIN.exp_mailed -f MAIN.exp_received")

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

        # Expiry mailbox lag
        total["fe-exp-lag"] = total.get("fe-exp_mailed", 0) - \
            total.get("fe-exp_received", 0)
        total["be-exp-lag"] = total.get("be-exp_mailed", 0) - \
            total.get("be-exp_received", 0)

        return total

    def extract(self):
        fields = ("n_object", "n_lru_nuked", "backend_fail", "threads",
                  "threads_created", "exp-lag")
        be_values = self.varnishstat(frontend=False)

        fe_values = self.varnishstat(frontend=True)

        for field in fields:
            self.val["fe-" + field] = fe_values.get("fe-" + field, 0)
            self.val["be-" + field] = be_values.get("be-" + field, 0)
