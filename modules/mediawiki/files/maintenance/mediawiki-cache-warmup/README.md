## Usage
```
$ python3 warmup.py -h
usage: warmup.py [-h] file {spread,clone,dry} ...

positional arguments:
  file                Path to a text file containing a newline-separated list
                      of URLs. Entries may use %server or %mobileServer.

optional arguments:
  -h, --help          show this help message and exit

commands:
  {spread,clone,dry}
    spread            distribute URLs via load balancer
    clone             send each URL to each server
    dry               print list of URLs to standard out
```

### Modes

- `warmup.py file spread [-h] target`
  - target: target host, e.g. appservers.svc.codfw.wmnet

- `warmup.py file clone [-h] cluster dc`
  - cluster: target cluster, e.g. appserver
  - dc: target data center, e.g. codfw

- `warmup.py file dry [-h] [--all]`
  - --all: dump the full list of URLs

## Output
```
$ python3 warmup.py urls-cluster.txt spread appservers.svc.eqiad.wmnet
Statistics:
  Wall time: 860.1 ms
  Count: 132 requests
  Fastest: 2.0 ms
  Average: 81.7 ms

Slowest 5 requests:
 - 669.2 ms (appservers.svc.eqiad.wmnet) https://sr.wikipedia.org/wiki/Main_Page
 - 425.4 ms (appservers.svc.eqiad.wmnet) https://ru.wikipedia.org/wiki/Main_Page
 - 366.6 ms (appservers.svc.eqiad.wmnet) https://fr.wikisource.org/wiki/Main_Page
 - 285.7 ms (appservers.svc.eqiad.wmnet) https://ru.wikinews.org/wiki/Main_Page
 - 264.3 ms (appservers.svc.eqiad.wmnet) https://species.wikimedia.org/wiki/Main_Page
```
