#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
  Generate index file for graphite-web

  This file supercedes the script 'graphite-build-search-index' which ships
  with the graphite-web package in Debian. The Debian script presumes that
  graphite-web and carbon are both running with uid / gid '_graphite', but we
  prefer to keep them distinct, because graphite-web should not be modifying
  Whisper files.

"""
import fnmatch
import os
import shutil
import tempfile

from graphite import settings


def iter_glob(dir, glob_pattern):
    """Recurse through `dir`, yielding files that match `glob_pattern`"""
    return (os.path.join(root, f) for root, _, fs in os.walk(dir)
            for f in fs if fnmatch.fnmatch(f, glob_pattern))


def format_entry(wsp_path):
    """Format a .wsp file path for inclusion in Graphite's index"""
    return wsp_path[len(settings.WHISPER_DIR):-4].replace('/', '.')


with tempfile.NamedTemporaryFile('wt', delete=False) as tmp:
    for whisper in iter_glob(settings.WHISPER_DIR, '*.wsp'):
        tmp.write(format_entry(whisper) + '\n')
    os.chmod(tmp.name, 0644)
    shutil.move(tmp.name, settings.INDEX_FILE)
