# -*- coding: utf-8 -*-
"""
  mwprof deployment module

"""
import subprocess


def make(repo):
    return subprocess.call('make clean && make', shell=True)
