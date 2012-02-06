###
###  This plugin for logtailer will crunch apache logs and return the following
###  metrics for each vhost that has received more than 5% of the hits in the
###  sampling period.  All other vhosts will be combined and their metrics will
###  be returned as "other".  The metrics for each vhost/other are:
###    * number of hits
###    * number of GET requests
###    * average duration of each hit
###    * 90th percentile of hit durations
###    * maximum hit duration
###    * number of HTTP 200-299 responses
###    * number of HTTP 300-399 responses
###    * number of HTTP 400-499 responses
###    * number of HTTP 500-599 responses
###

# cribbed the apachevhost logtailer for use crunching swift logs
# sample logs (delete, get, head, and put):
# format: month day time host process ip ip date action path httpver resp - useragent auth - - - - - dur
#  Feb  2 23:09:30 ms-fe1 proxy-server 10.0.11.21 10.0.11.21 02/Feb/2012/23/09/30 DELETE /v1/AUTH_43651b15-ed7a-40b6-b745-47666abf8dfe/wikipedia-commons-local-thumb.62/6/62/1_single_stroke_roll.svg/150px-1_single_stroke_roll.svg.png HTTP/1.0 204 - PHP-CloudFiles/1.7.10 mw%3Athumb%2CAUTH_tke52932a795f44f418bc2432dac1d81fc - - - - - 0.3470
#  Feb  2 23:08:07 ms-fe1 proxy-server 208.80.152.165 208.80.152.165 02/Feb/2012/23/08/07 GET /v1/AUTH_43651b15-ed7a-40b6-b745-47666abf8dfe/wikipedia-commons-local-thumb.42/4/42/Grattacielo_pirelli.JPG/220px-Grattacielo_pirelli.JPG HTTP/1.0 404 - Python-urllib/1.17 - - - - - - 0.2195
#  Feb  2 23:08:24 ms-fe1 proxy-server 10.0.6.210 10.0.6.210 02/Feb/2012/23/08/24 HEAD /v1/AUTH_43651b15-ed7a-40b6-b745-47666abf8dfe HTTP/1.0 204 - - mw%3Athumb%2CAUTH_tke52932a795f44f418bc2432dac1d81fc - - - - - 0.3117
#  Feb  2 23:08:08 ms-fe1 proxy-server 127.0.0.1 127.0.0.1 02/Feb/2012/23/08/08 PUT /v1/AUTH_43651b15-ed7a-40b6-b745-47666abf8dfe/wikipedia-commons-local-thumb.0d/0/0d/Hru%25C5%25A1ovany_u_Brna%252C_%25C5%25BEelezni%25C4%258Dn%25C3%25AD_stanice%252C_lokomotiva_362.087_%252802%2529.jpg/120px-Hru%25C5%25A1ovany_u_Brna%252C_%25C5%25BEelezni%25C4%258Dn%25C3%25AD_stanice%252C_loko HTTP/1.0 201 - - mw%3Athumb%2CAUTH_tke52932a795f44f418bc2432dac1d81fc 4037 - - - - 0.1491
# bhartshorne 2012-02-02

import time
import threading
import re
import copy

# local dependencies
from ganglia_logtailer_helper import GangliaMetricObject
from ganglia_logtailer_helper import LogtailerParsingException, LogtailerStateException

class SwiftProxyLogtailer(object):
    # only used in daemon mode
    period = 30
    def __init__(self):
        '''This function should initialize any data structures or variables
        needed for the internal state of the line parser.'''
        self.reset_state()
        self.lock = threading.RLock()

        # Dict for containing stats on each method
        self.stats = {}
        for m in ['GET', 'PUT', 'HEAD', 'DELETE', 'OTHER']:
            self.stats[m] = self.getBlankStats()

        # this is what will match the apache lines
        # see http://wikitech.wikimedia.org/view/Swift/Logging_and_Metrics for more detail
        # format: month day time host process ip ip date method path httpver resp - useragent auth - - - - - dur
        swiftLogFormat = '%date %host %process %client %remote_ip %slashdate %method %path %httpver %status %referrer %useragent %authtoken %reqbytes %respbytes %etag %transid %headers %dur'
        self.reg = re.compile(self.swiftLogToRegex(swiftLogFormat))

        # assume we're in daemon mode unless set_check_duration gets called
        self.dur_override = False


    def swiftLogToRegex(self, logFormat):
        logFormatDict = {
            '%date':                '(?P<date>[A-Z][a-z]+ +[0-9][0-9]? [0-9:]{8})', #eg "Feb  2 23:08:24"
            '%host':                '(?P<host>[^ ]+)',
            '%process':             '(?P<process>[^ ]+)',
            '%client':              '(?P<client>[^ ]+)',
            '%remote_ip':           '(?P<remote_ip>[^ ]+)',
            '%slashdate':           '(?P<slashdate>[^ ]+)',     #eg 02/Feb/2012/23/08/24
            '%method':              '(?P<method>[A-Z]+)',   #GET, HEAD, PUT, DELETE, etc.
            '%path':                '(?P<path>[^ ]+)',
            '%httpver':             '(?P<httpver>[^ ]+)',
            '%status':              '(?P<status>[^ ]+)',    # 404, 204, 200, etc.
            '%referrer':            '(?P<referrer>[^ ]+)',
            '%useragent':           '(?P<useragent>[^ ]+)',
            '%authtoken':           '(?P<authtoken>[^ ]+)',
            '%reqbytes':            '(?P<reqbytes>[^ ]+)',
            '%respbytes':           '(?P<respbytes>[^ ]+)',
            '%etag':                '(?P<etag>[^ ]+)',
            '%transid':             '(?P<transid>[^ ]+)',
            '%headers':             '(?P<headers>[^ ]+)',
            '%dur':                 '(?P<dur>[^ ]+)',
        }

        for (search, replace) in logFormatDict.iteritems():
            logFormat = logFormat.replace(search, replace)

        return "^%s$" % logFormat


    # example function for parse line
    # takes one argument (text) line to be parsed
    # returns nothing
    def parse_line(self, line):
        '''This function should digest the contents of one line at a time,
        updating the internal state variables.'''
        self.lock.acquire()

        try:
            regMatch = self.reg.match(line)
        except Exception, e:
            self.lock.release()
            raise LogtailerParsingException, "regmatch or contents failed with %s" % e

        if regMatch:
            lineBits = regMatch.groupdict()
            # all my stats are keyed off of method (GET, PUT, HEAD, etc)
            method = lineBits['method']
            if( method not in ['GET', 'PUT', 'HEAD', 'DELETE'] ):
                method = 'OTHER'
            # the only HTTP response codes I care about are 200, 204, and 404
            status = lineBits['status']
            if( status not in ['200', '201', '204', '404'] ):
                status = 'other'
            statusname = "durlist_%s" % status   # change 204 into 'durist_204'
            # finally, I want query duration (it's in seconds)
            req_time = float(lineBits['dur'])
            # store the query duration in its bucket; everything else will be calcalated from that
            self.stats[method][statusname].append(req_time)
        else:
            self.lock.release()
            raise LogtailerParsingException, "regmatch failed to match"

        self.lock.release()


    # Returns a dict of zeroed stats
    def getBlankStats(self):
        '''This function returns a dict of all the stats we\'d want for
        a vhost, zereod out.  This helps avoid undeclared keys when
        traversing the dictionary.'''

        blankData = {'durlist_200':   [],
                     'durlist_201':   [],
                     'durlist_204':   [],
                     'durlist_404':   [],
                     'durlist_other': []
                    }
        return blankData

    # example function for reset_state
    # takes no arguments
    # returns nothing
    def reset_state(self):
        '''This function resets the internal data structure to 0 (saving
        whatever state it needs).  This function should be called
        immediately after deep copy with a lock in place so the internal
        data structures can't be modified in between the two calls.  If the
        time between calls to get_state is necessary to calculate metrics,
        reset_state should store now() each time it's called, and get_state
        will use the time since that now() to do its calculations'''

        self.stats = {}
        self.last_reset_time = time.time()


    # example for keeping track of runtimes
    # takes no arguments
    # returns float number of seconds for this run
    def set_check_duration(self, dur):
        '''This function only used if logtailer is in cron mode.  If it is
        invoked, get_check_duration should use this value instead of calculating
        it.'''
        self.duration = dur
        self.dur_override = True


    def get_check_duration(self):
        '''This function should return the time since the last check.  If called
        from cron mode, this must be set using set_check_duration().  If in
        daemon mode, it should be calculated internally.'''
        if (self.dur_override):
            duration = self.duration
        else:
            cur_time = time.time()
            duration = cur_time - self.last_reset_time
            # the duration should be within 10% of period
            acceptable_duration_min = self.period - (self.period / 10.0)
            acceptable_duration_max = self.period + (self.period / 10.0)
            if (duration < acceptable_duration_min or duration > acceptable_duration_max):
                raise LogtailerStateException, "time calculation problem - duration (%s) > 10%% away from period (%s)" % (duration, self.period)
        return duration


    # example function for get_state
    # takes no arguments
    # returns a dictionary of (metric => metric_object) pairs
    def get_state(self):
        '''This function should acquire a lock, call deep copy, get the
        current time if necessary, call reset_state, then do its
        calculations.  It should return a list of metric objects.'''
        # get the data to work with
        self.lock.acquire()
        try:
            mydata = copy.deepcopy(self.stats)
            check_time = self.get_check_duration()
            self.reset_state()
            self.lock.release()
        except LogtailerStateException, e:
            # if something went wrong with deep_copy or the duration, reset and continue
            self.reset_state()
            self.lock.release()
            raise e

        combined = {}       # A dict containing stats for broken out & 'other' vhosts
        results  = []       # A list for all the Ganglia Log objects

        # for each method (get, put, etc.) we want to calculate 
        # - number of hits total
        # - avg, 90th, and max duration
        # - for each status code (200, 204, etc.)
        # - - number of hits
        # - - avg, 90th, and max duration
        # each metric will be named:
        #   method_hits, method_avg, method_90th, method_max
        #   method_status_hits, method_status_avg, method_status_90th, method_status_max
        # if method_status_hist is 0, avg, 90th, and max will not be reported.
        #   (for example, put will never return 200)

        totalhits = 0
        for (method, stats) in mydata.iteritems():
            # method = get, put, etc., stats = dict of statuses
            methodhits = 0
            methodstats = []
            for (status, durs) in stats.iteritems():
                # status = 'durlist_200', etc., durs = list of durations
                totalhits += len(durs)
                methodhits += len(durs)
                statushits = len(durs)
                if statushits == 0:
                    # skip calculating durations if the list is empty.
                    continue
                # at this point, we know there's stuff in durs
                # calculate avg, 90th, and max
                statusnum = status[8:] #turn 'durlist_200' into '200' (string, not int)
                #print "statusO: %s statusnum %s" % (status, statusnum)
                durs.sort()
                try:
                    combined['swift_%s_%s_hits' % (method, statusnum)] = statushits / check_time
                except ZeroDivisionError:
                    # I don't know what it means for statushits > 0 and check_time == 0, but meh.
                    combined['swift_%s_%s_hits' % (method, statusnum)] = 0
                #print "istatus 90th index is %s, len is %s" % (int(len(durs) * 0.9), len(durs))
                combined['swift_%s_%s_%s' % (method, statusnum, '90th')] = durs[int(len(durs) * 0.9)]
                combined['swift_%s_%s_%s' % (method, statusnum, 'max')] = durs[-1]
                combined['swift_%s_%s_%s' % (method, statusnum, 'avg')] = sum(durs) / len(durs)
                # combine status data for method stats
                methodstats = methodstats + durs
            # ok, all the statuses have been calculated, let's do summary for the method
            if methodhits == 0:
                # skip calculating durations if the list is empty
                continue
            durs = methodstats
            durs.sort()
            try:
                combined['swift_%s_hits' % (method)] = methodhits / check_time
            except ZeroDivisionError:
                combined['swift_%s_hits' % (method)] = 0
            #print "method 90th index is %s, len is %s" % (int(len(durs) * 0.9), len(durs))
            combined['swift_%s_%s' % (method, '90th')] = durs[int(len(durs) * 0.9)]
            combined['swift_%s_%s' % (method, 'max')] = durs[-1]
            #print durs
            #print ">> %s %s<<" % (sum(durs), len(durs))
            #combined['%s_%s' % (method, 'avg')] = sum(durs) / len(durs)
        combined['swift_hits'] = totalhits



        for metricname, metricval in combined.iteritems():
            # package up the data you want to submit
            if 'hits' in metricname:
                #print "metric info %s, %s, %s" % (metricname, metricval, 'hps')
                results.append(GangliaMetricObject(metricname, metricval, units='hps'))
            else:
                #print "metric info %s, %s, %s" % (metricname, metricval, 'sec')
                results.append(GangliaMetricObject(metricname, metricval, units='sec'))
        # return a list of metric objects
        return results
