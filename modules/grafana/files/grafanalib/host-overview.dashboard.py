import attr
import functools
import string

import grafanalib.core as G


def nonStacked(graph):
    return attr.assoc(
        graph,
        legend=G.Legend(current=True),
        lineWidth=1,
        nullPointMode=G.NULL_AS_ZERO,
        stack=False,
        fill=0,
        tooltip=G.Tooltip(
            valueType=G.INDIVIDUAL,
            sort=2,
        ),
    )


def stacked(graph):
    """Turn a graph into a stacked graph."""
    return attr.assoc(
        graph,
        legend=G.Legend(current=True),
        lineWidth=1,
        nullPointMode=G.NULL_AS_ZERO,
        stack=True,
        fill=1,
        tooltip=G.Tooltip(
            valueType=G.INDIVIDUAL,
            sort=2,
        ),
    )


def UtilizationGraph(title, expressions, yAxes=None, dataSource='$datasource', **kwargs):
  graph = G.Graph(
    title=title,
    dataSource=dataSource,
    targets=[G.Target(
      expr=e['expr'], legendFormat=e['legendFormat'], refId=r)
        for e, r in zip(expressions, string.ascii_uppercase)],
    editable=False,
    yAxes=[G.YAxis(format=G.SHORT_FORMAT, min=0),
           G.YAxis(show=False)],
    **kwargs,
  )
  return nonStacked(graph)


def PercentUtilizationGraph(title, expressions, yAxes=None, dataSource='$datasource', **kwargs):
  graph = G.Graph(
    title=title,
    dataSource=dataSource,
    targets=[G.Target(
      expr=e['expr'], legendFormat=e['legendFormat'], refId=r)
        for e, r in zip(expressions, string.ascii_uppercase)],
    editable=False,
    yAxes=[G.YAxis(format=G.PERCENT_UNIT_FORMAT, max=1.0, min=0),
           G.YAxis(show=False)],
    **kwargs,
  )
  return stacked(graph)


def SaturationGraph(title, expressions, dataSource='$datasource', thresholds=None, **kwargs):
  graph = G.Graph(
    title=title,
    dataSource=dataSource,
    targets=[G.Target(
      expr=e['expr'], legendFormat=e['legendFormat'], refId=r)
        for e, r in zip(expressions, string.ascii_uppercase)],
    editable=False,
    yAxes=[G.YAxis(format=G.SHORT_FORMAT, min=0),
           G.YAxis(show=False)],
    fill=0,
    **kwargs,
  )
  if thresholds is not None:
    graph.targets.extend([G.Target(
        expr=t['expr'],
        legendFormat=t['legendFormat']) for t in thresholds])
    graph.seriesOverrides.extend([
        {'alias': t['legendFormat'],
         'legend': False,
         'fill': 0,
         'stack': False,
        } for t in thresholds ])
  return nonStacked(graph)

# XXX do a real errorsgraph
ErrorsGraph = SaturationGraph

# guidelines
# - one axis
# - max 4 lines per graph
# - zero based
# - if gauges, have a threshold
# - if percent, 0 - 100% on axis
# - utilization graphs should be stacked
# - use fill style to indicate if values are being stacked (typical for utilization)
#   if values are independent (like in FS utilization) and not stacked, don't fill
# - consider bars style for errors and saturation?
# - make sure colors are distinct
# XXX provide description for graphs
# XXX check Text panel, https://github.com/weaveworks/grafanalib/issues/61
# XXX yaxes customization for units, ditto for percentage

templates = [
  {
    "allValue": None,
    "current": {},
    "datasource": "$datasource",
    "hide": 0,
    "includeAll": False,
    "label": None,
    "multi": False,
    "name": "server",
    "options": [],
    "query": "label_values(node_boot_time, instance)",
    "refresh": 1,
    "regex": "/(.*):.*/",
    "sort": 1,
    "tagValuesQuery": None,
    "tags": [],
    "tagsQuery": None,
    "type": "query",
    "useTags": False
  },
      {
        "current": {
          "selected": True,
          "text": "eqiad prometheus/ops",
          "value": "eqiad prometheus/ops"
        },
        "datasource": None,
        "hide": 0,
        "includeAll": False,
        "label": "",
        "multi": False,
        "name": "datasource",
        "options": [],
        "query": "prometheus",
        "refresh": 1,
        # XXX parametrize
        #"regex": "/\\/ops/",
        "regex": "",
        "type": "datasource"
      },
]

dashboard = G.Dashboard(
  title='Host overview',
  time=G.Time('now-3h', 'now'),
  templating=G.Templating(templates),
  refresh='2m',
  rows=[
    G.Row(panels=[
        PercentUtilizationGraph('CPU: utilization', [
          {'expr': 'sum by (mode) '
                   '(irate(node_cpu{mode!="idle",instance=~"$server:.*"}[5m])) / '
                   'scalar(count(node_cpu{mode="idle",instance=~"$server:.*"}))',
           'legendFormat': '{{mode}}',
          },
          ]
        ),
        SaturationGraph('CPU: saturation', [
          {'expr': 'node_load1{instance=~"$server:.*"}',
           'legendFormat': 'load 1m',
          },
          ],
          thresholds=[
          {'expr': 'sum(count(node_cpu{job="node",mode="idle",instance=~"$server:.*"}) by (cpu))',
           'legendFormat': 'CPUs'},
          ],
        )
    ]),

    G.Row(panels=[
        stacked(UtilizationGraph('Memory: utilization', [
            {'expr': 'node_memory_MemTotal{instance=~"$server:.*"}',
             'legendFormat': 'Total',
            },
            {'expr': 'node_memory_Cached{instance=~"$server:.*"}',
             'legendFormat': 'Cached',
            },
            {'expr': 'node_memory_MemTotal{instance=~"$server:.*"} -'
                     'node_memory_Writeback{instance=~"$server:.*"} -'
                     'node_memory_Cached{instance=~"$server:.*"} -'
                     'node_memory_Buffers{instance=~"$server:.*"} -'
                     'node_memory_MemFree{instance=~"$server:.*"}',
             'legendFormat': 'Used',
            },
          ],
          seriesOverrides=[{'alias': 'Total', 'fill': '0', 'stacked': False}],
        )),
        SaturationGraph('Memory: saturation', [
            {'expr': 'rate(node_vmstat_pswpin{instance=~"$server:.*"}[5m])',
             'legendFormat': 'pages/swpin',
            },
            {'expr': 'rate(node_vmstat_pswpout{instance=~"$server:.*"}[5m])',
             'legendFormat': 'pages/swpout',
            },
          ],
        )
    ]),

    G.Row(panels=[
        UtilizationGraph('Network: utilization', [
            {'expr': 'sum(irate(node_network_receive_bytes{instance=~"$server.*",device=~"(eth|en[0-9a-z]+)[0-9]*"}[5m]) > 0)',
             'legendFormat': 'rx/bytes',
            },
            {'expr': 'sum(irate(node_network_transmit_bytes{instance=~"$server.*",device=~"(eth|en[0-9a-z]+)[0-9]*"}[5m]) > 0)',
             'legendFormat': 'tx/bytes',
            },
          ],
        ),
        SaturationGraph('Network: saturation', [
            {'expr':
                'irate(node_network_transmit_drop{instance=~"$server.*",device=~"(eth|en[0-9a-z]+)[0-9]*"}[5m]) +'
                'irate(node_network_receive_drop{instance=~"$server.*",device=~"(eth|en[0-9a-z]+)[0-9]*"}[5m])',
             'legendFormat': 'drop/{{device}}',
            },
            {'expr': 'irate(node_network_transmit_errs{instance=~"$server.*",device=~"(eth|en[0-9a-z]+)[0-9]*"}[5m]) + '
                'irate(node_network_receive_errs{instance=~"$server.*",device=~"(eth|en[0-9a-z]+)[0-9]*"}[5m])',
             'legendFormat': 'errs/{{device}}',
            },
          ],
        )
    ]),

    G.Row(panels=[
        PercentUtilizationGraph('Disk: utilization', [
            {'expr': 'irate(node_disk_io_time_ms{instance=~"$server:.*",device=~"[vs]d[a-z]+"}[5m]) / 1000',
             'legendFormat': '{{device}}',
            },
          ],
        ),
        SaturationGraph('Disk: saturation', [
            {'expr':'node_disk_io_now{instance=~"$server.*",device=~"[vs]d[a-z]+"}',
             'legendFormat': '{{device}}',
            },
          ],
        )
    ]),

    G.Row(panels=[
        UtilizationGraph('Socket: utilization', [
            {'expr': 'node_sockstat_TCP_tw{instance=~"$server:.*"}',
             'legendFormat': 'tcp/timewait',
            },
            {'expr': 'node_sockstat_UDP_inuse{instance=~"$server:.*"}',
             'legendFormat': 'udp/inuse',
            },
            {'expr': 'node_sockstat_TCP_inuse{instance=~"$server:.*"}',
             'legendFormat': 'tcp/inuse',
            },
          ],
        ),
        ErrorsGraph('Socket: errors', [
            {'expr':'rate(node_netstat_Tcp_InErrs{instance=~"$server.*"}[5m])',
             'legendFormat': 'tcp/inerrs',
            },
            {'expr':'rate(node_netstat_Tcp_AttemptFails{instance=~"$server.*"}[5m])',
             'legendFormat': 'tcp/attemptfails',
            },
            {'expr':'rate(node_netstat_Udp_RcvbufErrors{instance=~"$server.*"}[5m]) +'
                    'rate(node_netstat_Udp_SndbufErrors{instance=~"$server.*"}[5m])',
             'legendFormat': 'udp/buferr',
            },
            {'expr':'rate(node_netstat_Udp_InErrors{instance=~"$server.*"}[5m])',
             'legendFormat': 'udp/inerrs',
            },
            {'expr':'rate(node_netstat_Icmp_InErrors{instance=~"$server.*"}[5m]) +'
                    'rate(node_netstat_Icmp_OutErrors{instance=~"$server.*"}[5m])',
             'legendFormat': 'icmp/errs',
            },
          ],
        )
    ]),

    G.Row(panels=[
        PercentUtilizationGraph('Filesystem: utilization', [
            {'expr': '1 - (node_filesystem_avail{instance=~"$server:.*",fstype!~"(tmpfs|rpc_pipefs|debugfs|nfs|rootfs).*"} /'
                     'node_filesystem_size{instance=~"$server:.*"})',
             'legendFormat': '{{mountpoint}} (bytes, {{fstype}})',
            },
            {'expr': '1 - (node_filesystem_files_free{instance=~"$server:.*",fstype!~"(tmpfs|rpc_pipefs|debugfs|nfs|rootfs).*"} /'
                     'node_filesystem_files{instance=~"$server:.*"})',
             'legendFormat': '{{mountpoint}} (inodes, {{fstype}})',
            },
          ],
          span=6,
        ),
    ]),

    G.Row(panels=[
        UtilizationGraph('Misc: utilization', [
            #{'expr': 'node_entropy_available_bits{instance=~"$server:.*"}'
            # 'legendFormat': 'entropy available',
            #},
            {'expr': 'rate(node_forks{instance=~"$server.*"}[5m])',
             'legendFormat': 'forks',
            },
            {'expr': 'rate(node_intr{instance=~"$server.*"}[5m])',
             'legendFormat': 'interrupts',
            },
          ],
          span=6,
        ),
    ]),
  ],
).auto_panel_ids()
