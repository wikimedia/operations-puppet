## Manual actions needed:
### configcluster
On the configcluster, do the dirty things needed to be able to scp to the pontoon-puppet server, then:
```
scp /var/lib/puppet/ssl/private_keys/pontoon-conf42.appservers.eqiad1.wikimedia.cloud.pem pontoon-puppet01.appservers.eqiad1.wikimedia.cloud:/etc/puppet/private/modules/secret/secrets/ssl/pontoon-conf42.appservers.eqiad1.wikimedia.cloud.key
```
On the pontoon-puppet server
```
cp /var/lib/puppet/ssl/ca/signed/pontoon-conf42.appservers.eqiad1.wikimedia.cloud.pem /etc/puppet/private/modules/secret/secrets/ssl/pontoon-conf42.appservers.eqiad1.wikimedia.cloud.crt
chmod a+r /etc/puppet/private/modules/secret/secrets/ssl/pontoon-conf42.appservers.eqiad1.wikimedia.cloud.key
```

### mediawiki::appserver
Same dirty ssl hack than `configcluster`
