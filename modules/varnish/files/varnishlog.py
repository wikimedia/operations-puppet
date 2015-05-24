# -*- coding: utf-8 -*-
"""
  varnishlog.py
  ~~~~~~~~~~~~~

  Python 2 and 3 bindings for the Varnish shared log API.

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

  Author: Ori Livneh

"""
import ctypes
import ctypes.util
import threading

try:
    import queue
except ImportError:
    import Queue as queue


varnishapi_so = ctypes.util.find_library('varnishapi')
if varnishapi_so is None:
    raise OSError('Unable to locate varnishapi library.')
varnishapi = ctypes.CDLL(varnishapi_so)
varnishapi.VSM_New.restype = ctypes.c_void_p

VSL_handler_f = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_void_p, ctypes.c_uint,
                                 ctypes.c_uint, ctypes.c_uint, ctypes.c_uint,
                                 ctypes.POINTER(ctypes.c_char),
                                 ctypes.c_ulonglong)

# https://github.com/varnish/Varnish-Cache/blob/master/include/tbl/vsl_tags.h
VSL_Tags = (
    'Debug', 'Error', 'CLI', 'StatSess', 'ReqEnd', 'SessionOpen',
    'SessionClose', 'BackendOpen', 'BackendXID', 'BackendReuse',
    'BackendClose', 'HttpGarbage', 'Backend', 'Length', 'FetchError',
    'RxRequest', 'RxResponse', 'RxStatus', 'RxURL', 'RxProtocol', 'RxHeader',
    'TxRequest', 'TxResponse', 'TxStatus', 'TxURL', 'TxProtocol', 'TxHeader',
    'ObjRequest', 'ObjResponse', 'ObjStatus', 'ObjURL', 'ObjProtocol',
    'ObjHeader', 'LostHeader', 'TTL', 'Fetch_Body', 'VCL_acl', 'VCL_call',
    'VCL_trace', 'VCL_return', 'VCL_error', 'ReqStart', 'Hit', 'HitPass',
    'ExpBan', 'ExpKill', 'WorkThread', 'ESI_xmlerror', 'Hash',
    'Backend_health', 'VCL_Log', 'Gzip'
)


class VarnishLog:
    """Represents a Varnish log handler.

    This object implements the iterator protocol, so you can iterate on it
    to get log records. For example:

    >>> for tag, text in VarnishLog(instance_name='frontend', tag='ReqEnd'):
    ...     print('%s: %s' % (tag, text))

    """

    def __init__(self, instance_name=None, tag=None, limit=None):
        """
        Create a VarnishLog instance.

        Args:
          instance_name: Name of the varnishd instance to get logs from.
          tag: Include log entries with the specified tag.
          limit: Maximum number of log records to show.
        """
        self.queue = queue.Queue(maxsize=1)
        self.vd = varnishapi.VSM_New()
        varnishapi.VSL_Setup(self.vd)
        if instance_name:
            self._vsl_arg('n', instance_name)
        if tag:
            self._vsl_arg('i', tag)
        if limit:
            self._vsl_arg('k', str(limit))

    def _vsl_arg(self, arg, value):
        if varnishapi.VSL_Arg(self.vd, ord(arg), value.encode('utf-8')) != 1:
            raise OSError('VSL_Arg(vd, "%s", "%s")' % (arg, value))

    def _worker(self):
        def vsl_handler(priv, tag, fd, length, spec, ptr, bitmap):
            tag_text = VSL_Tags[tag]
            text = ctypes.string_at(ptr, length)
            self.queue.put((tag_text, text))
            return 0

        vsl_handler_ptr = VSL_handler_f(vsl_handler)
        while 1:
            if varnishapi.VSL_Dispatch(self.vd, vsl_handler_ptr, self.vd) < 0:
                self.queue.put(None)
                break

    def __iter__(self):
        if varnishapi.VSL_Open(self.vd, 1) != 0:
            raise OSError('VSL_Open(vd, 1)')
        threading.Thread(target=self._worker).start()
        return iter(self.queue.get, None)
