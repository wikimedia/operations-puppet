/** @scratch /configuration/config.js/1
 * == Configuration
 * config.js is where you will find the core Kibana configuration. This file
 * contains parameters that must be set before kibana is run for the first time.
 */
define(['settings'],
function (Settings) {
  "use strict";

  /** @scratch /configuration/config.js/2
   * === Parameters
   */
  return new Settings({

    /** @scratch /configuration/config.js/5
     * ==== elasticsearch
     *
     * Our apache config acts as a reverse proxy to the elasticsearch cluster.
     */
    elasticsearch: '//' + window.location.hostname,

    /** @scratch /configuration/config.js/5
     * ==== default_route
     *
     * This is the default landing page when you don't specify a dashboard to
     * load. You can specify files, scripts or saved dashboards here. For
     * example, if you had saved a dashboard called `WebLogs' to elasticsearch
     * you might use:
     *
     * +default_route: '/dashboard/elasticsearch/WebLogs',+
     */
    default_route     : <%= @default_route.to_pson %>,

    /** @scratch /configuration/config.js/5
     * ==== kibana-int
     *
     * The default ES index to use for storing Kibana specific object
     * such as stored dashboards
     */
    kibana_index: "kibana-int",

    /** @scratch /configuration/config.js/5
     * ==== panel_name
     *
     * An array of panel modules available. Panels will only be loaded when
     * they are defined in the dashboard, but this list is used in the "add
     * panel" interface.
     */
    panel_names: [
      'histogram',
      'map',
      'pie',
      'table',
      'filtering',
      'timepicker',
      'text',
      'hits',
      'column',
      'trends',
      'bettermap',
      'query',
      'terms',
      'stats',
      'sparklines'
    ]
  });
});
