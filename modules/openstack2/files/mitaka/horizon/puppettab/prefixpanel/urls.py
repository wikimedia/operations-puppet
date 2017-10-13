# Copyright (c) 2016 Andrew Bogott for Wikimedia Foundation
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
from django.conf.urls import url, patterns

from wikimediapuppettab.prefixpanel import prefixpanel
from wikimediapuppettab import views

urlpatterns = patterns(
    '',
    url(r'^$', prefixpanel.IndexView.as_view(), name='index'),
    url(r'^(?P<prefix>[^/]+)/(?P<tenantid>[^/]+)/'
        '(?P<roleid>[^/]+)/applypuppetrole$',
        views.ApplyRoleView.as_view(), name='applypuppetrole'),
    url(r'^(?P<prefix>[^/]+)/(?P<tenantid>[^/]+)/'
        '(?P<roleid>[^/]+)/removepuppetrole$',
        views.RemoveRoleView.as_view(), name='removepuppetrole'),
    url(r'^(?P<prefix>[^/]+)/(?P<tenantid>[^/]+)/'
        'edithiera$',
        views.EditHieraView.as_view(), name='edithiera'),
    url(r'^(?P<tenantid>[^/]+)/'
        'newprefix$',
        prefixpanel.IndexView.as_view(), name='newprefix'),
    url(r'^(?P<prefix>[^/]+)/(?P<tenantid>[^/]+)/'
        'removepuppetprefix$',
        views.RemovePrefixView.as_view(), name='removepuppetprefix'),
)
