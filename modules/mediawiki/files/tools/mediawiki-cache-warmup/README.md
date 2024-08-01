## Usage
```
usage: warmup.py [-h] [--dry-run] [--full] file {spread,clone} ...

positional arguments:
  file            Path to a text file containing a newline-separated list of
                  URLs. Entries may use %server or %mobileServer.

options:
  -h, --help      show this help message and exit
  --dry-run       do not sent requests; exit after printing a sample of the
                  URL and target lists that would have been used
  --full          print full URL and target lists, rather than a sample

commands:
  {spread,clone}
    spread        distribute URLs via load balancer
    clone         send each URL to each mediawiki kubernetes pod
```

### Modes

`spread` mode:

```
usage: warmup.py file spread [-h] target

positional arguments:
  target      target host:port, e.g. mw-web.svc.codfw.wmnet:4450

options:
  -h, --help  show this help message and exit
```

`clone` mode:

```
usage: warmup.py file clone [-h] cluster namespace

positional arguments:
  cluster     target kubernetes cluster, e.g. codfw
  namespace   target kubernetes namespace, e.g. mw-web

options:
  -h, --help  show this help message and exit
```

## Output
```
$ python3 warmup.py urls-cluster.txt spread mw-web.svc.eqiad.wmnet:4450
Sending 132 requests to each of 1 targets.
Requests:
 GET https://vi.wikipedia.org/w/api.php?format=json&action=query&list=recentchanges
 GET https://incubator.m.wikimedia.org/wiki/Main_Page
 GET https://tr.wikipedia.org/wiki/Main_Page
 GET https://he.wikipedia.org/w/api.php?format=json&action=query&list=recentchanges
 GET https://cs.m.wikipedia.org/wiki/Main_Page
 GET https://zh.wiktionary.org/wiki/Main_Page
 GET https://ja.wikipedia.org/w/api.php?format=json&action=query&list=recentchanges
 GET https://m.wikidata.org/wiki/Main_Page
 GET https://ja.m.wikipedia.org/wiki/Main_Page
 GET https://en.m.wikinews.org/wiki/Main_Page
 ... (and 122 more)
Targets:
 mw-web.svc.eqiad.wmnet:4450

Statistics:
  Wall time: 860.1 ms
  Count: 132 requests
  Fastest: 2.0 ms
  Average: 81.7 ms

Slowest 5 requests:
 - 669.2 ms (mw-web.svc.eqiad.wmnet:4450) https://sr.wikipedia.org/wiki/Main_Page
 - 425.4 ms (mw-web.svc.eqiad.wmnet:4450) https://ru.wikipedia.org/wiki/Main_Page
 - 366.6 ms (mw-web.svc.eqiad.wmnet:4450) https://fr.wikisource.org/wiki/Main_Page
 - 285.7 ms (mw-web.svc.eqiad.wmnet:4450) https://ru.wikinews.org/wiki/Main_Page
 - 264.3 ms (mw-web.svc.eqiad.wmnet:4450) https://species.wikimedia.org/wiki/Main_Page
```