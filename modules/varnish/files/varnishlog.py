# -*- coding: utf-8 -*-
"""
  varnishlog.py
  ~~~~~~~~~~~~~

  Python 2 and 3 bindings for the Varnish shared log API.
  This uses ctypes to interface with the Varnish C API,
  and abstracts away those details.

  Usage:

    from varnishlog import varnishlog
    def my_callback(tag, value, transaction_id, is_client):
      print(tag, value, transaction_id, is_client)

    varnishlog(
        [
            ('n', 'frontend'),
            ('-i', 'RxMethod'),
            ('-c', '')
        ],
        my_callback
    ])

  Copyright 2015 Ori Livneh <ori@wikimedia.org>

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  Author: Ori Livneh and Andrew Otto

"""
import ctypes
import ctypes.util
import sys


varnishapi_so = ctypes.util.find_library('varnishapi')
if varnishapi_so is None:
    raise OSError('Unable to locate varnishapi library.')
varnishapi = ctypes.CDLL(varnishapi_so)
varnishapi.VSM_New.restype = ctypes.c_void_p

VSL_handler_f = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_void_p, ctypes.c_uint,
                                 ctypes.c_uint, ctypes.c_uint, ctypes.c_uint,
                                 ctypes.POINTER(ctypes.c_char),
                                 ctypes.c_ulonglong)

# Index of Varnish log tags ('RxURL', 'ReqEnd', etc.)
VSL_Tags = (ctypes.c_char_p * 256).in_dll(varnishapi, 'VSL_tags')

# This flag indicates that the log record was generated as a result
# of communication with a client. Defined in varnishapi.h.
VSL_S_CLIENT = 1

# This flag indicates that the log record was generated as a result
# of communication with a backend server. Defined in varnishapi.h.
VSL_S_BACKEND = 2


def varnishlog(vsl_args, callback):
    """
    Calls callback for every VSL entry that matches filters
    provided in vsl_args.

    Args:
        vsl_args: List of tuples of the form (arg, value)
        callback: function that takes these arguments:
                  (tag, value, transaction_id, is_client)
    """
    vd = varnishapi.VSM_New()
    varnishapi.VSL_Setup(vd)

    # Initialize with provided vsl_args
    for (arg, value) in vsl_args:
        if varnishapi.VSL_Arg(vd, ord(arg), value.encode('utf-8')) != 1:
            raise OSError('VSL_Arg(vd, "%s", "%s")' % (arg, value))

    if varnishapi.VSL_Open(vd, 1) != 0:
        raise OSError('VSL_Open(vd, 1)')

    def _vsl_handler(priv, tag_id, fd, length, spec, ptr, bitmap):
        tag = VSL_Tags[tag_id]
        record = ctypes.string_at(ptr, length)

        # Call the provided callback
        callback(tag, record, fd, bool(spec & VSL_S_CLIENT))
        return 0

    # This will call _vsl_handler for every VSL entry,
    # which will in turn call the provided callback
    # with pythonic arguments.
    varnishapi.VSL_Dispatch(
        vd,
        VSL_handler_f(_vsl_handler),
        None
    )


if __name__ == '__main__':
    def print_tags_callback(tag, value, transaction_id, is_client):
        print("%s\t%s\t%s\t%s" % (tag, value, transaction_id, is_client))

    # Guess at parsing CLI args into a list of VSL arg tuples.
    # This is a stupid for/while loop.  Is there a slicker python way?
    vsl_args = []
    i = 1
    while i < len(sys.argv):
        # Remove any '-' from this arg.
        arg = sys.argv[i].translate(None, '-')
        # If this is the end, or if the next arg has a '-',
        # assume this is a switch that does not take a parameter.
        if i == len(sys.argv) - 1 or '-' in sys.argv[i+1]:
            vsl_args.append((arg, ''))
        # Else this arg takes a parameter.
        else:
            i += 1
            vsl_args.append((arg, sys.argv[i]))
        i += 1

    varnishlog(vsl_args, print_tags_callback)
