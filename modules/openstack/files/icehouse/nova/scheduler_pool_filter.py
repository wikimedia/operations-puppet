# Copyright (c) 2015 Andrew Bogott for Wikimedia Foundation
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

from oslo.config import cfg
from nova.openstack.common import log as logging

from nova import db
from nova.scheduler import filters

LOG = logging.getLogger(__name__)

pool_opt = cfg.ListOpt('wmf_scheduler_hosts_pool',
                       help='Lists of hosts permitted to schedule new instances',
                       default=None)
CONF = cfg.CONF
CONF.register_opt(pool_opt)


class SchedulerPoolFilter(filters.BaseHostFilter):
    """Filters Hosts according to a simple config setting"""

    # This won't change within a request
    run_filter_once_per_request = True

    def host_passes(self, host_state, filter_properties):
        pool = CONF.wmf_scheduler_hosts_pool
        if pool is None:
            LOG.debug("Host pool is unspecified, allowing all available hosts.")
            return True
        else:
            LOG.debug("Filtering according to the host pool: %s" % pool)
            return host_state.host in pool
