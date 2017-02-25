## Usage
```
$ node warmup.js

Usage: node warmup.js FILE MODE [spread_target|clone_cluster] [clone_dc]
 - file          Path to a text file containing a newline-separated list of urls. Entries may use %server or %mobileServer.
 - mode          One of:
                  "spread": distribute urls via load-balancer
                  "clone-debug": send urls to debug server
                  "clone": send each url to each server

Examples:
 $ warmup.js urls-cluster.txt spread appservers.svc.codfw.wmnet
 $ warmup.js urls-server.txt clone-debug
 $ warmup.js urls-server.txt clone appservers codfw
```

## Output
```
$ node warmup.js urls-server.txt clone-debug
...
[2017-02-02T01:05:29.414Z] Request https://jbo.wiktionary.org/w/load.php?debug=false&modules=jquery%2Cmediawiki&only=scripts
[2017-02-02T01:05:29.422Z] Request https://ne.wikibooks.org/w/load.php?debug=false&modules=jquery%2Cmediawiki&only=scripts
Statistics:
- timing: min = 0.134s | max = 28.894s | avg = 1.040s | total = 46s
- concurrency: min = 0 | max = 49 | avg = 48

Done!
```
