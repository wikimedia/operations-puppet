import json
import webob.dec

from oslo_config import cfg
from oslo_log import log as logging
from oslo_middleware import base
from oslo_serialization import base64

LOG = logging.getLogger(__name__)

_opts = [
    cfg.StrOpt('default_user_data_file',
               default="",
               help='Default user_data file to inject into new VMs')
]


# Detect server creation POSTs and inject an optional user_data
#  file into the new server.  This allows us to specify a cloud-wide
#  firstboot script.
#
# Note that this does not switch on image type; if we need different
#  boot scripts for different image types this will have to be amended
#  (or the boot script itself can contain switches).
class InjectUserData(base.ConfigurableMiddleware):

    def __init__(self, application, conf=None):
        super(InjectUserData, self).__init__(application, conf)
        self.oslo_conf.register_opts(_opts, group='api')

    @webob.dec.wsgify
    def __call__(self, req):
        if req.environ['REQUEST_METHOD'] == 'POST':
            if 'server' in req.json:
                if 'user_data' not in req.json['server']:
                    if self._conf_get('default_user_data_file', 'api'):
                        # Read the user_data file into a string, encode,
                        # and jam into req
                        file = open(self._conf_get('default_user_data_file', 'api'), mode='r')
                        user_data = file.read()
                        file.close()

                        LOG.warning("Injecting default user_data into new server request.")
                        jsonbody = req.json
                        jsonbody['server']['user_data'] = base64.encode_as_bytes(user_data)
                        req.body = json.dumps(jsonbody)
        return self.application
