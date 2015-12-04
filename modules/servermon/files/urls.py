from django.conf.urls.defaults import *
from django.conf import settings

# Uncomment the next two lines to enable the admin & hwdoc:
from django.contrib import admin
admin.autodiscover()

urlpatterns = patterns(
    '',
    (r'^/?$',           'servermon.projectwide.views.index'),
    (r'^hosts/$',       'servermon.updates.views.hostlist'),
    (r'^hosts/(.*)',    'servermon.updates.views.host'),
    (r'^packages/$',    'servermon.updates.views.packagelist'),
    (r'^packages/(.*)', 'servermon.updates.views.package'),
    (r'^inventory/?$',  'servermon.puppet.views.inventory'),
    (r'^search/?$',     'servermon.projectwide.views.search'),
    (r'^advancedsearch/$', 'servermon.projectwide.views.advancedsearch'),
    (r'^query/?$',      'servermon.puppet.views.query'),
    # Opensearch
    url(r'^opensearch.xml$', 'servermon.projectwide.views.opensearch',
        name="opensearch"),
    url(r'^suggest/$', 'servermon.projectwide.views.suggest',
        name="opensearchsuggestions"),
    # Uncomment the next lines to enable the admin & hwdoc:
    (r'^admin/',        include(admin.site.urls)),
    # (r'^admin/doc/',    include('django.contrib.admindocs.urls')),
    (r'^hwdoc/',        include('servermon.hwdoc.urls')),
)

# Static files
if settings.DEBUG:
    urlpatterns += patterns('django.views.static',
                            (r'^static/(?P<path>.*)$', 'serve',
                                {'document_root': settings.MEDIA_ROOT}),
                            )
