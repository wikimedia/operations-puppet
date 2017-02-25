### Usage

```sh
node warmup.js urls-cluster.txt spread

node warmup.js urls-server.txt clone-debug
```


### Output
```
$ node warmup.js

Usage: node warmup.js [targets] [mode]

 - targets 	Path to a text file containing newline-separated list of urls, may contain %server or %mobileServer.
 - mode 	One of "spread" (via load-balancer) or "clone" (send each url to all servers)

$ node warmup.js urls-server.txt clone-debug
...
[2017-02-02T01:05:29.414Z] Request https://jbo.wiktionary.org/w/load.php?debug=false&modules=jquery%2Cmediawiki&only=scripts
[2017-02-02T01:05:29.422Z] Request https://ne.wikibooks.org/w/load.php?debug=false&modules=jquery%2Cmediawiki&only=scripts
Statistics:
- timing: min = 0.134s | max = 28.894s | avg = 1.040s | total = 46s
- concurrency: min = 0 | max = 49 | avg = 48

Done!
```
