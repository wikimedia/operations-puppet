To use, make a role that reads hiera configuration like this:

```
dashiki::instance { hiera('dashiki_instances'): }
```

In hiera, you would need to define dashiki instances like:

```
dashiki_config_VitalSigns:
    wikiConfig  : VitalSigns
    layout      : metrics-by-project
    piwik       : 'piwik.wmflabs.org,3'
    url         : 'vital-signs.wmflabs.org'

dashiki_config_VisualEditorAndWikitext:
    wikiConfig  : VisualEditorAndWikitext
    layout      : compare
    piwik       : 'piwik.wmflabs.org,1'
    url         : 'edit-analysis.wmflabs.org'

dashiki_instances:
    - VitalSigns
    - VisualEditorAndWikitext
    ...
```
