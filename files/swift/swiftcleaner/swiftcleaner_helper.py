##
## helper functions for swiftcleaner and switftcleanermanager
##

import urllib2
# make a class to hold the swift authentication token and fetch a new one when necessary.
class Token():
    _token = 'AUTH_abc123'
    _user = 'account:user'
    _key = 'xxxxxxxx'
    _useragent = 'swiftcleaner'

    @classmethod
    def update_auth_creds(cls, conf):
        try:
            cls._user = conf['user']
            cls._key = conf['key']
            cls._useragent = conf['useragent']
        except KeyError:
            # if the cnofiguration doesn't have the one we want, juts ignore all of them.
            pass

    @classmethod
    def get_token(cls):
        # if we already have the token, return it.
        if(cls._token != None):
            #print "  old token; returning token %s" % cls._token
            return cls._token
        # otherwise get a new token from Swift
        # eg curl -k -v -H 'X-Auth-User: mw:thumb' -H 'X-Auth-Key: xxxxxxxxxxxx' http://ms-fe.pmtpa.wmnet/auth/v1.0
        headers = {}
        headers['X-Auth-User'] = cls._user
        headers['X-Auth-Key'] = cls._key
        headers['User-Agent'] = cls._useragent
        req = urllib2.Request('http://ms-fe.pmtpa.wmnet/auth/v1.0', headers=headers)
        try:
            resp = urllib2.urlopen(req)
        except urllib2.HTTPError, e:
            print "getting token excepted with %s" % e
            raise
        authtoken = resp.info()['X-Storage-Token']
        authurl = resp.info()['X-Storage-Url']
        cls._token = authtoken
        return authtoken

    @classmethod
    def clear_token(cls):
        # force the next request for a token to get a fresh one
        cls._token = None

def read_config(conffile, conf):
    # which configs are what type?
    intconfs = ['numthreads', 'objsperthread']
    floatconfs = ['delay']
    boolconfs = ['test']
    #try and pull in optinos from the config file
    try:
        configfh = open(conffile)
        for line in configfh.readlines():
            if "#" in line:
                # throw away the part after the comment character
                (line, comment) = line.split("#", 1)
            try:
                (opt,val) = line.split("=")
            except ValueError:
                # no = sign in the line, skip this line
                continue
            opt = opt.strip().lower()
            val = val.strip()
            # cast val
            if opt in intconfs:
                val = int(val)
            if opt in floatconfs:
                val = float(val)
            if opt in boolconfs:
                # if it's set to anything but 'False', go ahead and enter testing mode.  safer that way.
                val = (False if val == False or val == 'False' else True)
            conf[opt] = val
        configfh.close()
    except (IOError, TypeError), e:
        # if the conf file doesn't exist, that's cool.  no biggy.
        #print "passing with exp %s" % e
        pass
    return conf

# vim: set nu list expandtab tabstop=4 shiftwidth=4 autoindent:
