# coding: utf-8


# Copyright (c) 2013-2016 Shohei Tanaka(@xcir)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

# https://github.com/xcir/python-varnishapi
# v50.18

from ctypes import *
import getopt
import time


class VSC_level_desc(Structure):
    _fields_ = [
        ("verbosity", c_uint),  # unsigned verbosity;
        ("label", c_char_p),    # const char *label;  /* label */
        ("sdesc", c_char_p),    # const char *sdesc;  /* short description */
        ("ldesc", c_char_p),    # const char *ldesc;  /* long description */
    ]


class VSC_type_desc(Structure):
    _fields_ = [
        ("label", c_char_p),  # const char *label;    /* label */
        ("sdesc", c_char_p),  # const char *sdesc;    /* short description */
        ("ldesc", c_char_p),  # const char *ldesc;    /* long description */
    ]


class VSM_fantom(Structure):
    _fields_ = [
        ("chunk", c_void_p),      # struct VSM_chunk *chunk;
        ("b", c_void_p),          # void *b;   /* first byte of payload */
        ("e", c_void_p),          # void *e;   /* first byte past payload */
        # ("priv", c_uint),   #uintptr_t         priv; /* VSM private */
        ("priv", c_void_p),       # uintptr_t priv; /* VSM private */
        ("_class", c_char * 8),   # char class[VSM_MARKER_LEN];
        ("type", c_char * 8),     # char type[VSM_MARKER_LEN];
        ("ident", c_char * 128),  # char ident[VSM_IDENT_LEN];
    ]


class VSC_section(Structure):
    _fields_ = [
        ("type", c_char_p),                # const char *type;
        ("ident", c_char_p),               # const char *ident;
        ("desc", POINTER(VSC_type_desc)),  # const struct VSC_type_desc *desc;
        ("fantom", POINTER(VSM_fantom)),   # struct VSM_fantom *fantom;
    ]


class VSC_desc(Structure):
    _fields_ = [
        # const char *name;     /* field name                   */
        ("name", c_char_p),
        # const char *fmt;      /* field format ("uint64_t")    */
        ("fmt", c_char_p),
        # int flag;             /* 'c' = counter, 'g' = gauge   */
        ("flag", c_int),
        # const char *sdesc;    /* short description            */
        ("sdesc", c_char_p),
        # const char *ldesc;    /* long description             */
        ("ldesc", c_char_p),
        # const struct VSC_level_desc *level;
        ("level", POINTER(VSC_level_desc)),
    ]


class VSC_point(Structure):
    _fields_ = [
        # const struct VSC_desc *desc;  /* point description            */
        ("desc", POINTER(VSC_desc)),
        # ("ptr", c_void_p), #const volatile void *ptr; /* field value  */
        # const volatile void *ptr;     /* field value                  */
        ("ptr", POINTER(c_ulonglong)),
        # const struct VSC_section *section;
        ("section", POINTER(VSC_section)),
    ]

# typedef int VSC_iter_f(void *priv, const struct VSC_point *const pt);
VSC_iter_f = CFUNCTYPE(
    c_int,
    c_void_p,
    POINTER(VSC_point)
)

#


class VSLC_ptr(Structure):
    _fields_ = [
        # const uint32_t *ptr; /* Record pointer */
        ("ptr", POINTER(c_uint32)),
        # unsigned priv;
        ("priv", c_uint),
    ]


class VSL_cursor(Structure):
    _fields_ = [
        ("rec", VSLC_ptr),        # struct VSLC_ptr rec;
        ("priv_tbl", c_void_p),   # const void      *priv_tbl;
        ("priv_data", c_void_p),  # void            *priv_data;
    ]


class VSL_transaction(Structure):
    _fields_ = [
        ("level", c_uint),           # unsigned               level;
        ("vxid", c_int32),           # int32_t                vxid;
        ("vxid_parent", c_int32),    # int32_t                vxid_parent;
        ("type", c_int),             # enum VSL_transaction_e type;
        ("reason", c_int),           # enum VSL_reason_e      reason;
        ("c", POINTER(VSL_cursor)),  # struct VSL_cursor      *c;
    ]


class VTAILQ_HEAD(Structure):
    _fields_ = [
        # struct type *vtqh_first;    /* first element */
        ("vtqh_first", c_void_p),
        # struct type **vtqh_last;    /* addr of last next element */
        ("vtqh_last", POINTER(c_void_p)),
    ]


class vbitmap(Structure):
    _fields_ = [
        ("bits", c_void_p),  # VBITMAP_TYPE    *bits;
        ("nbits", c_uint),   # unsigned        nbits;
    ]


class vsb(Structure):
    _fields_ = [
        # unsigned   magic;
        ("magic", c_uint),
        # char       *s_buf;    /* storage buffer */
        ("s_buf", c_char_p),
        # int        s_error;   /* current error code */
        ("s_error", c_int),
        # ssize_t    s_size;    /* size of storage buffer */
        # ("s_size", c_ssize_t),
        # ssize_t    s_len;     /* current length of string */
        # ("s_len", c_ssize_t),

        # ssize_t    s_size;    /* size of storage buffer */
        ("s_size", c_long),
        # ssize_t    s_len;     /* current length of string */
        ("s_len", c_long),
        # int        s_flags;   /* flags */
        ("s_flags", c_int),
    ]


class VSL_data(Structure):
    _fields_ = [
        ("magic", c_uint),                  # unsigned           magic;
        ("diag", POINTER(vsb)),             # struct vsb         *diag;
        ("flags", c_uint),                  # unsigned           flags;
        ("vbm_select", POINTER(vbitmap)),   # struct vbitmap     *vbm_select;
        ("vbm_supress", POINTER(vbitmap)),  # struct vbitmap     *vbm_supress;
        ("vslf_select", VTAILQ_HEAD),       # vslf_list          vslf_select;
        ("vslf_suppress", VTAILQ_HEAD),     # vslf_list          vslf_suppress;
        ("b_opt", c_int),                   # int                b_opt;
        ("c_opt", c_int),                   # int                c_opt;
        ("C_opt", c_int),                   # int                C_opt;
        ("L_opt", c_int),                   # int                L_opt;
        ("T_opt", c_double),                # double             T_opt;
        ("v_opt", c_int),                   # int                v_opt;
    ]

# typedef int VSLQ_dispatch_f(struct VSL_data *vsl, struct VSL_transaction
# * const trans[], void *priv);
VSLQ_dispatch_f = CFUNCTYPE(
    c_int,
    POINTER(VSL_data),
    POINTER(POINTER(VSL_transaction)),
    c_void_p
)


class VarnishAPIDefine40:

    def __init__(self):
        self.VSL_COPT_TAIL = (1 << 0)
        self.VSL_COPT_BATCH = (1 << 1)
        self.VSL_COPT_TAILSTOP = (1 << 2)
        self.SLT_F_BINARY = (1 << 1)

        '''
        //////////////////////////////
        enum VSL_transaction_e {
            VSL_t_unknown,
            VSL_t_sess,
            VSL_t_req,
            VSL_t_bereq,
            VSL_t_raw,
            VSL_t__MAX,
        };
        '''
        self.VSL_t_unknown = 0
        self.VSL_t_sess = 1
        self.VSL_t_req = 2
        self.VSL_t_bereq = 3
        self.VSL_t_raw = 4
        self.VSL_t__MAX = 5

        '''
        //////////////////////////////
        enum VSL_reason_e {
            VSL_r_unknown,
            VSL_r_http_1,
            VSL_r_rxreq,
            VSL_r_esi,
            VSL_r_restart,
            VSL_r_pass,
            VSL_r_fetch,
            VSL_r_bgfetch,
            VSL_r_pipe,
            VSL_r__MAX,
        };
        '''
        self.VSL_r_unknown = 0
        self.VSL_r_http_1 = 1
        self.VSL_r_rxreq = 2
        self.VSL_r_esi = 3
        self.VSL_r_restart = 4
        self.VSL_r_pass = 5
        self.VSL_r_fetch = 6
        self.VSL_r_bgfetch = 7
        self.VSL_r_pipe = 8
        self.VSL_r__MAX = 9


class LIBVARNISHAPI:

    def __init__(self, lib):

        #LIBVARNISHAPI_1.0
        #VSM_New;
        self.VSM_New = lib.VSM_New
        self.VSM_New.restype = c_void_p

        #VSM_Diag;
        #VSM_n_Arg;
        self.VSM_n_Arg = lib.VSM_n_Arg
        self.VSM_n_Arg.restype = c_int
        self.VSM_n_Arg.argtypes = [c_void_p, c_char_p]

        #VSM_Name;
        self.VSM_Name = lib.VSM_Name
        self.VSM_Name.restype = c_char_p
        self.VSM_Name.argtypes = [c_void_p]

        #VSM_Delete;
        self.VSM_Delete = lib.VSM_Delete
        self.VSM_Delete.argtypes = [c_void_p]

        #VSM_Open;
        self.VSM_Open = lib.VSM_Open
        self.VSM_Open.restype = c_int
        self.VSM_Open.argtypes = [c_void_p]

        #VSM_ReOpen;
        #VSM_Seq;
        #VSM_Head;
        #VSM_Find_Chunk;
        #VSM_Close;
        #VSM_iter0;
        #VSM_intern;
        #
        #VSC_Setup;
        #VSC_Arg;
        #VSC_Open;
        #VSC_Main;
        #VSC_Iter;
        self.VSC_Iter = lib.VSC_Iter
        self.VSC_Iter.argtypes = [c_void_p, c_void_p, VSC_iter_f, c_void_p]

        #
        #VSL_Setup;
        #VSL_Open;
        #VSL_Arg;
        self.VSL_Arg = lib.VSL_Arg
        self.VSL_Arg.restype = c_int
        self.VSL_Arg.argtypes = [c_void_p, c_int, c_char_p]

        #VSL_H_Print;
        #VSL_Select;
        #VSL_NonBlocking;
        #VSL_Dispatch;
        #VSL_NextLog;
        #VSL_Matched;
        #
        #VCLI_WriteResult;
        #VCLI_ReadResult;
        #VCLI_AuthResponse;
        #
        ## Variables
        #VSL_tags;

        #LIBVARNISHAPI_1.1
        # Functions:
        #VSL_Name2Tag;
        self.VSL_Name2Tag = lib.VSL_Name2Tag
        self.VSL_Name2Tag.restype = c_int
        self.VSL_Name2Tag.argtypes = [c_char_p, c_int]

        #LIBVARNISHAPI_1.2
        # Functions:
        #VSL_NextSLT;
        #VSM_Error;
        self.VSM_Error = lib.VSM_Error
        self.VSM_Error.restype = c_char_p
        self.VSM_Error.argtypes = [c_void_p]

        #VSM_Get;

        #LIBVARNISHAPI_1.3
        #VSM_Abandoned;
        #VSM_ResetError;
        self.VSM_ResetError = lib.VSM_ResetError
        self.VSM_ResetError.argtypes = [c_void_p]

        #VSM_StillValid;
        #VSC_Mgt;
        #VSC_LevelDesc;
        #VSL_New;
        self.VSL_New = lib.VSL_New
        self.VSL_New.restype = c_void_p

        #VSL_Delete;
        self.VSL_Delete = lib.VSL_Delete
        self.VSL_Delete.argtypes = [c_void_p]

        #VSL_Error;
        self.VSL_Error = lib.VSL_Error
        self.VSL_Error.restype = c_char_p
        self.VSL_Error.argtypes = [c_void_p]

        #VSL_ResetError;
        #VSL_CursorVSM;
        self.VSL_CursorVSM = lib.VSL_CursorVSM
        self.VSL_CursorVSM.restype = POINTER(VSL_cursor)
        self.VSL_CursorVSM.argtypes = [c_void_p, c_void_p, c_uint]

        #VSL_CursorFile;
        self.VSL_CursorFile = lib.VSL_CursorFile
        self.VSL_CursorFile.restype = POINTER(VSL_cursor)
        self.VSL_CursorFile.argtypes = [c_void_p, c_char_p, c_uint]

        #VSL_DeleteCursor;
        #VSL_Next;
        self.VSL_Next = lib.VSL_Next
        self.VSL_Next.restype = c_int
        self.VSL_Next.argtypes = [POINTER(VSL_cursor)]

        #VSL_Match;
        self.VSL_Match = lib.VSL_Match
        self.VSL_Match.restype = c_int
        self.VSL_Match.argtypes = [c_void_p, POINTER(VSL_cursor)]

        #VSL_Print;
        #VSL_PrintTerse;
        #VSL_PrintAll;
        #VSL_PrintTransactions;
        #VSL_WriteOpen;
        #VSL_Write;
        #VSL_WriteAll;
        #VSL_WriteTransactions;
        #VSLQ_New;
        self.VSLQ_New = lib.VSLQ_New
        self.VSLQ_New.restype = c_void_p
        self.VSLQ_New.argtypes = [c_void_p, POINTER(POINTER(VSL_cursor)), c_int, c_char_p]

        #VSLQ_Delete;
        self.VSLQ_Delete = lib.VSLQ_Delete
        self.VSLQ_Delete.argtypes = [POINTER(c_void_p)]

        #VSLQ_Dispatch;
        self.VSLQ_Dispatch = lib.VSLQ_Dispatch
        self.VSLQ_Dispatch.restype = c_int
        self.VSLQ_Dispatch.argtypes = [c_void_p, VSLQ_dispatch_f, c_void_p]

        #VSLQ_Flush;
        self.VSLQ_Flush = lib.VSLQ_Flush
        self.VSLQ_Flush.restype = c_int
        self.VSLQ_Flush.argtypes = [c_void_p, VSLQ_dispatch_f, c_void_p]

        #VSLQ_Name2Grouping;
        self.VSLQ_Name2Grouping = lib.VSLQ_Name2Grouping
        self.VSLQ_Name2Grouping.restype = c_int
        self.VSLQ_Name2Grouping.argtypes = [c_char_p, c_int]

        #VSL_Glob2Tags;
        #VSL_List2Tags;
        #VSM_N_Arg;
        self.VSM_N_Arg = lib.VSM_N_Arg
        self.VSM_N_Arg.restype = c_int
        self.VSM_N_Arg.argtypes = [c_void_p, c_char_p]

        #VSL_Check;
        #VSL_ResetCursor;
        ## Variables:
        #VSLQ_grouping;
        #VSL_tagflags;

        #LIBVARNISHAPI_1.4
        #VNUM;
        #VSLQ_SetCursor;
        #VSM_IsOpen;

        #LIBVARNISHAPI_1.5
        #VUT_Error;
        #VUT_g_Arg;
        #VUT_Arg;
        #VUT_Setup;
        #VUT_Init;
        #VUT_Fini;
        #VUT_Main;
        #VUT;
        #VTIM_mono;
        #VTIM_real;
        #VTIM_sleep;
        #VSB_new;
        #VSB_destroy;
        #VSB_error;
        #VSB_cat;
        #VSB_putc;
        #VSB_printf;
        #VSB_clear;
        #VSB_finish;
        #VSB_len;
        #VSB_data;
        #VAS_Fail;
        #VCS_Message;


        if hasattr(lib, "VUT_Init"):
            self.apiversion = 1.5
        elif hasattr(lib, "VSM_IsOpen"):
            self.apiversion = 1.4
        else:
            self.apiversion = 1.3
        

class VSLUtil:

    def tag2Var(self, tag, data):
        ret = {'key': '', 'val': '', 'vkey': ''}
        if tag not in self.__tags:
            return ret

        r = self.__tags[tag]
        ret['vkey'] = r.split(' ', 1)[-1].split('.', 1)[0]
        if r == '':
            return ret
        elif r[-1:] == '.':
            spl = data.split(': ', 1)
            ret['key'] = r + spl[0].rstrip(': ')
            ret['val'] = ''
            if len(spl) > 1:
                ret['val'] = spl[1]
        else:
            ret['key'] = r
            ret['val'] = data
        return (ret)

    def tag2VarName(self, tag, data):
        return self.tag2Var(tag, data)['key']

    __tags = {
        'Debug': '',
        'Error': '',
        'CLI': '',
        'SessOpen': '',
        'SessClose': '',
        'BackendOpen': '',  # Change key count at varnish41(4->6)
        'BackendStart': '', # 4.1.3~
        'BackendReuse': '',
        'BackendClose': '',
        'HttpGarbage': '',
        'Backend': '',
        'Length': '',
        'FetchError': '',
        'BogoHeader': '',
        'LostHeader': '',
        'TTL': '',
        'Fetch_Body': '',
        'VCL_acl': '',
        'VCL_call': '',
        'VCL_trace': '',
        'VCL_return': '',
        'ReqStart': 'client.ip',
        'Hit': '',
        'HitPass': '',
        'ExpBan': '',
        'ExpKill': '',
        'WorkThread': '',
        'ESI_xmlerror': '',
        'Hash': '',  # Change log data type(str->bin)
        'Backend_health': '',
        'VCL_Log': '',
        'VCL_Error': '',
        'Gzip': '',
        'Link': '',
        'Begin': '',
        'End': '',
        'VSL': '',
        'Storage': '',
        'Timestamp': '',
        'ReqAcct': '',
        'ESI_BodyBytes': '',  # Only Varnish40X
        'PipeAcct': '',
        'BereqAcct': '',
        'ReqMethod': 'req.method',
        'ReqURL': 'req.url',
        'ReqProtocol': 'req.proto',
        'ReqStatus': '',
        'ReqReason': '',
        'ReqHeader': 'req.http.',
        'ReqUnset': 'unset req.http.',
        'ReqLost': '',
        'RespMethod': '',
        'RespURL': '',
        'RespProtocol': 'resp.proto',
        'RespStatus': 'resp.status',
        'RespReason': 'resp.reason',
        'RespHeader': 'resp.http.',
        'RespUnset': 'unset resp.http.',
        'RespLost': '',
        'BereqMethod': 'bereq.method',
        'BereqURL': 'bereq.url',
        'BereqProtocol': 'bereq.proto',
        'BereqStatus': '',
        'BereqReason': '',
        'BereqHeader': 'bereq.http.',
        'BereqUnset': 'unset bereq.http.',
        'BereqLost': '',
        'BerespMethod': '',
        'BerespURL': '',
        'BerespProtocol': 'beresp.proto',
        'BerespStatus': 'beresp.status',
        'BerespReason': 'beresp.reason',
        'BerespHeader':   'beresp.http.',
        'BerespUnset':    'unset beresp.http.',
        'BerespLost':     '',
        'ObjMethod':      '',
        'ObjURL':         '',
        'ObjProtocol':    'obj.proto',
        'ObjStatus': 'obj.status',
        'ObjReason': 'obj.reason',
        'ObjHeader': 'obj.http.',
        'ObjUnset':     'unset obj.http.',
        'ObjLost':      '',
        'Proxy':        '',  # Only Varnish41x
        'ProxyGarbage': '',  # Only Varnish41x
        'VfpAcct':      '',  # Only Varnish41x
        'Witness':      '',  # Only Varnish41x
        'H2RxHdr':   '',  # Only Varnish50x
        'H2RxBody':  '',  # Only Varnish50x
        'H2TxHdr':   '',  # Only Varnish50x
        'H2TxBody':  '',  # Only Varnish50x
    }


class VarnishAPI:

    def __init__(self, sopath='libvarnishapi.so.1'):
        self.lib = cdll[sopath]
        self.lva = LIBVARNISHAPI(self.lib)
        self.defi = VarnishAPIDefine40()
        self._cb = None
        self.vsm = self.lva.VSM_New()
        self.d_opt = 0

        VSLTAGS = c_char_p * 256
        self.VSL_tags = []
        self.VSL_tags_rev = {}
        tmp = VSLTAGS.in_dll(self.lib, "VSL_tags")
        for i in range(0, 255):
            if tmp[i] is None:
                self.VSL_tags.append(None)
            else:
                key = tmp[i].decode("utf8", "replace")
                self.VSL_tags.append(key)
                self.VSL_tags_rev[key] = i

        VSLTAGFLAGS = c_uint * 256
        self.VSL_tagflags = []
        tmp = VSLTAGFLAGS.in_dll(self.lib, "VSL_tagflags")
        for i in range(0, 255):
            self.VSL_tagflags.append(tmp[i])

        VSLQGROUPING = c_char_p * 4
        self.VSLQ_grouping = []
        tmp = VSLQGROUPING.in_dll(self.lib, "VSLQ_grouping")
        for i in range(0, 3):
            self.VSLQ_grouping.append(tmp[i])

        self.error = ''

    def VSL_TAG(self, ptr):
        tag = ptr[0] >> 24
        return tag

    def VSL_DATA(self, ptr, isbin=False):
        length = ptr[0] & 0xffff
        if isbin:
            data = string_at(ptr, length + 8)[8:]
        else:
            data = string_at(ptr, length + 8)[8:-1].decode("utf8", "replace")
        return data

    def ArgDefault(self, op, arg):
        if op == "n":
            # Set Varnish instance name.
            i = self.lva.VSM_n_Arg(self.vsm, arg)
            if i <= 0:
                self.error = "%s" % self.lva.VSM_Error(self.vsm).rstrip()
                return(i)
        elif op == "N":
            # Set VSM file.
            i = self.lva.VSM_N_Arg(self.vsm, arg)
            if i <= 0:
                self.error = "%s" % self.lva.VSM_Error(self.vsm).rstrip()
                return(i)
            self.d_opt = 1
        return(None)


class VarnishStat(VarnishAPI):

    def __init__(self, opt='', sopath='libvarnishapi.so.1'):
        VarnishAPI.__init__(self, sopath)
        self.name = ''
        if len(opt) > 0:
            self.__setArg(opt)
        if self.lva.VSM_Open(self.vsm):
            self.error = "Can't open VSM file (%s)" % self.lva.VSM_Error(
                self.vsm).rstrip()
        else:
            self.name = self.lva.VSM_Name(self.vsm)

    def __setArg(self, opt):
        opts, args = getopt.getopt(opt, "N:n:")
        error = 0
        for o in opts:
            op = o[0].lstrip('-')
            arg = o[1]
            self.__Arg(op, arg.encode("utf8", "replace"))

        if error:
            self.error = error
            return(0)
        return(1)

    def __Arg(self, op, arg):
        # default
        i = VarnishAPI.ArgDefault(self, op, arg)
        if i < 0:
            return(i)

    def _getstat(self, priv, pt):

        if not bool(pt):
            return(0)
        val = pt[0].ptr[0]

        sec = pt[0].section
        key = ''

        type = sec[0].fantom[0].type.decode("utf8", "replace")
        ident = sec[0].fantom[0].ident.decode("utf8", "replace")
        if type != '':
            key += type + '.'
        if ident != '':
            key += ident + '.'
        key += pt[0].desc[0].name.decode("utf8", "replace")

        self._buf[key] = {'val': val, 'desc': pt[0].desc[0].sdesc.decode("utf8", "replace")}

        return(0)

    def getStats(self):
        self._buf = {}
        self.lva.VSC_Iter(self.vsm, None, VSC_iter_f(self._getstat), None)
        return self._buf

    def Fini(self):
        if self.vsm:
            self.lva.VSM_Delete(self.vsm)
            self.vsm = 0


class VarnishLog(VarnishAPI):

    def __init__(self, opt='', sopath='libvarnishapi.so.1', dataDecode=True):
        VarnishAPI.__init__(self, sopath)

        self.vut = VSLUtil()
        self.vsl = self.lva.VSL_New()
        self.vslq = None
        self.__g_arg = 0
        self.__q_arg = None
        self.__r_arg = 0
        self.name = ''
        self.dataDecode = dataDecode

        if len(opt) > 0:
            self.__setArg(opt)

        self.__Setup()

    def __setArg(self, opt):
        opts, args = getopt.getopt(opt, "bcCdx:X:r:q:N:n:I:i:g:")
        error = 0
        for o in opts:
            op = o[0].lstrip('-')
            arg = o[1]
            self.__Arg(op, arg.encode("utf8", "replace"))

        # Check
        if self.__r_arg and self.vsm:
            error = "Can't have both -n and -r options"

        if error:
            self.error = error
            return(0)
        return(1)

    def __Arg(self, op, arg):
        i = VarnishAPI.ArgDefault(self, op, arg)
        if i is not None:
            return(i)

        if op == "d":
            # Set log cursor at the head.
            self.d_opt = 1
        elif op == "g":
            # Specify the grouping.
            self.__g_arg = self.__VSLQ_Name2Grouping(arg)
            if self.__g_arg == -2:
                self.error = "Ambiguous grouping type: %s" % (arg)
                return(self.__g_arg)
            elif self.__g_arg < 0:
                self.error = "Unknown grouping type: %s" % (arg)
                return(self.__g_arg)
        # elif op == "P":
        # Not support PID(-P) option.
        elif op == "q":
            # VSL-query
            self.__q_arg = arg
        elif op == "r":
            # Read log from the binary file.
            self.__r_arg = arg
        else:
            # default
            i = self.__VSL_Arg(op, arg)
            if i < 0:
                self.error = "%s" % self.lva.VSL_Error(self.vsl).decode("utf8", "replace")
            return(i)

    def __Setup(self):
        if self.__r_arg:
            c = self.lva.VSL_CursorFile(self.vsl, self.__r_arg, 0)
        else:
            if self.lva.VSM_Open(self.vsm):
                self.error = "Can't open VSM file (%s)" % self.lva.VSM_Error(
                    self.vsm).decode("utf8", "replace").rstrip()
                return(0)
            self.name = self.lva.VSM_Name(self.vsm)

            if self.d_opt:
                tail = self.defi.VSL_COPT_TAILSTOP
            else:
                tail = self.defi.VSL_COPT_TAIL

            c = self.lva.VSL_CursorVSM(
                self.vsl, self.vsm, tail | self.defi.VSL_COPT_BATCH)

        if not c:
            self.error = "Can't open log (%s)" % self.lva.VSL_Error(self.vsl).decode("utf8", "replace")
            return(0)
        # query
        self.vslq = self.lva.VSLQ_New(self.vsl, c, self.__g_arg, self.__q_arg)
        if not self.vslq:
            self.error = "Query expression error:\n%s" % self.lva.VSL_Error(
                self.vsl).decode("utf8", "replace")
            return(0)

        return(1)

    def __cbMain(self, cb, priv=None):
        self._cb = cb
        self._priv = priv
        if not self.vslq:
            # Reconnect VSM
            time.sleep(0.1)
            if self.lva.VSM_Open(self.vsm):
                self.lva.VSM_ResetError(self.vsm)
                return(1)
            c = self.lva.VSL_CursorVSM(
                self.vsl, self.vsm,
                self.defi.VSL_COPT_TAIL | self.defi.VSL_COPT_BATCH)
            if not c:
                self.lva.VSM_ResetError(self.vsm)
                self.lva.VSM_Close(self.vsm)
                return(1)
            self.vslq = self.lva.VSLQ_New(
                self.vsl, c, self.__g_arg, self.__q_arg)
            self.error = 'Log reacquired'
        i = self.lva.VSLQ_Dispatch(
            self.vslq, VSLQ_dispatch_f(self._callBack), None)
        return(i)

    def Dispatch(self, cb, priv=None):
        i = self.__cbMain(cb, priv)
        if i > -2:
            return i
        if not self.vsm:
            return i

        self.lva.VSLQ_Flush(self.vslq, VSLQ_dispatch_f(self._callBack), None)
        self.lva.VSLQ_Delete(byref(cast(self.vslq, c_void_p)))
        self.vslq = None
        if i == -2:
            self.error = "Log abandoned"
            self.lva.VSM_Close(self.vsm)
        if i < -2:
            self.error = "Log overrun"
        return i

    def Fini(self):
        if self.vslq:
            self.lva.VSLQ_Delete(byref(cast(self.vslq, c_void_p)))
            self.vslq = 0
        if self.vsl:
            self.lva.VSL_Delete(self.vsl)
            self.vsl = 0
        if self.vsm:
            self.lva.VSM_Delete(self.vsm)
            self.vsm = 0

    def __VSL_Arg(self, opt, arg='\0'):
        return self.lva.VSL_Arg(self.vsl, ord(opt), arg)

    def __VSLQ_Name2Grouping(self, arg):
        return self.lva.VSLQ_Name2Grouping(arg, -1)

    def _callBack(self, vsl, pt, fo):
        idx = -1
        while 1:
            idx += 1
            t = pt[idx]
            if not bool(t):
                break
            tra = t[0]
            cbd = {
                'level': tra.level,
                'vxid': tra.vxid,
                'vxid_parent': tra.vxid_parent,
                'reason': tra.reason,
            }


            while 1:
                i = self.lva.VSL_Next(tra.c)
                if i < 0:
                    return (i)
                if i == 0:
                    break
                if not self.lva.VSL_Match(self.vsl, tra.c):
                    continue

                # decode vxid type ...
                ptr = tra.c[0].rec.ptr
                cbd['length'] = ptr[0] & 0xffff
                cbd['tag'] = self.VSL_TAG(ptr)
                if ptr[1] & (1 << 30):
                    cbd['type'] = 'c'
                elif ptr[1] & (1 << 31):
                    cbd['type'] = 'b'
                else:
                    cbd['type'] = '-'
                cbd['isbin'] = self.VSL_tagflags[cbd['tag']] & self.defi.SLT_F_BINARY
                isbin = cbd['isbin'] == self.defi.SLT_F_BINARY or not self.dataDecode
                cbd['data'] = self.VSL_DATA(ptr, isbin)

                if self._cb:
                    self._cb(self, cbd, self._priv)
        return(0)
