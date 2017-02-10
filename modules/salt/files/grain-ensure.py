#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
  grain-ensure
  ~~~~~~~~~~~~

  This tool is designed for use in noninteractive scripts that need to set,
  remove, or check for the presence of some value in a grain.

  Usage: grain-ensure ACTION GRAIN VALUE
  Where ACTION may be one of:

    contains
      If the grain contains the value, return 0. Otherwise, return 1.

    add
      If the grain does not contain the value, add it and return 0.
      If it already contains the value, return 1.

    remove
      If the grain contains the value, remove it and return 0.
      Otherwise, return 1.


  Copyright (c) 2013 Wikimedia Foundation <info@wikimedia.org>

  Permission to use, copy, modify, and distribute this software for any
  purpose with or without fee is hereby granted, provided that the above
  copyright notice and this permission notice appear in all copies.

  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

"""
import argparse

import salt.client
import salt.config
import salt.minion


class SaltLocalCaller(salt.client.Caller):
    """A salt.client.Caller that doesn't require the salt master.
    See <http://docs.saltstack.com/en/latest/ref/clients/#salt.client.Caller>.
    """
    def __init__(self, c_path='/etc/salt/minion'):
        self.opts = salt.config.minion_config(c_path)
        self.opts['file_client'] = 'local'
        self.sminion = salt.minion.SMinion(self.opts)


caller = SaltLocalCaller()


def get(grain):
    values = caller.function('grains.get', grain)
    return values if isinstance(values, list) else [values]


def add(grain, value):
    values = get(grain)
    if value not in values:
        values.append(value)
        caller.function('grains.setval', grain, values)
        return True
    return False


def setval(grain, value):
    caller.function('grains.setval', grain, value)
    return True


def contains(grain, value):
    return value in get(grain)


def remove(grain, value):
    values = get(grain)
    if value in values:
        values.remove(value)
        caller.function('grains.setval', grain, values)
        return True
    return False


actions = {'add': add, 'remove': remove, 'contains': contains, 'set': setval}

ap = argparse.ArgumentParser()
ap.add_argument('action', choices=actions)
ap.add_argument('grain')
ap.add_argument('value')
args = ap.parse_args()

action = actions.get(args.action)
ok = action(args.grain, args.value)

raise SystemExit(0 if ok else 1)
