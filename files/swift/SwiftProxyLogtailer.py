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

import time
import threading
import re
import copy

# local dependencies
from ganglia_logtailer_helper import GangliaMetricObject
from ganglia_logtailer_helper import LogtailerParsingException, LogtailerStateException

class ApacheVHostLogtailer(object):
    # only used in daemon mode
    period = 30
    def __init__(self):
        '''This function should initialize any data structures or variables
        needed for the internal state of the line parser.'''
        self.reset_state()
        self.lock = threading.RLock()

        # Dict for containing stats on each vhost
        self.stats = {}

        # A vhost must receive at least this % of the hits to be broken out from 'other'
        self.percentToBeHot = 0.05

        # this is what will match the apache lines
        apacheLogFormat = '%v %P %u %{%Y-%m-%dT%H:%M:%S}t %D %s %>s %I %O %B %a \"%{X-Forwarded-For}i\" \"%r\".*'
        self.reg = re.compile(self.apacheLogToRegex(apacheLogFormat))

        # assume we're in daemon mode unless set_check_duration gets called
        self.dur_override = False


    def apacheLogToRegex(self, logFormat):
        logFormatDict = {'%v':      '(?P<server_name>[^ ]+)',
            '%h':                   '(?P<remote_host>[^ ]+)',
            '%a':                   '(?P<remote_ip>[^ ]+)',
            '%P':                   '(?P<pid>[^ ]+)',           # PID
            '%u':                   '(?P<auth_user>[^ ]+)',     # HTTP-auth username
            '%t':                   '\[(?P<date>[^\]]+)\]',     # default date format
            '%{%Y-%m-%dT%H:%M:%S}t':'(?P<date>[^ ]+)',          # custom date format
            '%D':                   '(?P<req_time>[^ ]+)',      # req time in microsec
            '%s':                   '(?P<retcode>[^ ]+)',       # initial response code
            '%>s':                  '(?P<final_retcode>[^ ]+)', # final response code
            '%b':                   '(?P<req_size_clf>[^ ]+)',  # request size in bytes in CLF
            '%B':                   '(?P<req_size>[^ ]+)',      # req size in bytes
            '%I':                   '(?P<req_size_wire>[^ ]+)', # req size in bytes on the wire (+SSL, +compression)
            '%O':                   '(?P<resp_size_wire>[^ ]+)',# response size in bytes
            '%X':                   '(?P<conn_status>[^ ]+)',   # connection status
            '\"%r\"':               '"(?P<request>[^"]+)"',     # request (GET / HTTP/1.0)
            '\"%q\"':               '"(?P<query_string>[^"]+)"',# the query string
            '\"%U\"':               '"(?P<url>[^"]+)"',         # the URL requested
            '\"%{X-Forwarded-For}i\"': '"(?P<xfwd_for>[^"]+)"', # X-Forwarded-For header
            '\"%{Referer}i\"':      '"(?P<referrer>[^"]+)"',
            '\"%{User-Agent}i\"':   '"(?P<user_agent>[^"]+)"',
            '%{cookie}n':           '(?P<cookie>[^ ]+)'}

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

            # For brevity, pull out the servername from the line list
            server_name = lineBits['server_name']
            
            # Make this server_name a key for an empty dict if we have
            # never seen it before.
            self.stats[server_name] = \
                self.stats.get(server_name, self.getBlankStats())

            self.stats[server_name]['num_hits'] += 1

            if( 'GET' in lineBits['request'] ):
                self.stats[server_name]['num_gets'] += 1

            rescode = int(lineBits['final_retcode'])
            if( (rescode >= 200) and (rescode < 300) ):
                self.stats[server_name]['num_200'] += 1
            elif( (rescode >= 300) and (rescode < 400) ):
                self.stats[server_name]['num_300'] += 1
            elif( (rescode >= 400) and (rescode < 500) ):
                self.stats[server_name]['num_400'] += 1
            elif( (rescode >= 500) and (rescode < 600) ):
                self.stats[server_name]['num_500'] += 1
            
            # capture request duration
            req_time = float(lineBits['req_time'])
            # convert to seconds
            req_time = req_time / 1000000
            # Add up the req_time in the req_time_avg field, we'll divide later
            self.stats[server_name]['req_time_avg'] += req_time
            
            # store for 90th % calculation
            self.stats[server_name]['req_time_90th_list'].append(req_time)
        else:
            raise LogtailerParsingException, "regmatch failed to match"
        
        self.lock.release()
    

    # Returns a dict of zeroed stats
    def getBlankStats(self):
        '''This function returns a dict of all the stats we\'d want for
        a vhost, zereod out.  This helps avoid undeclared keys when
        traversing the dictionary.'''

        blankData = {'num_hits':        0,
                     'num_gets':        0,
                     'num_200':         0,
                     'num_300':         0,
                     'num_400':         0,
                     'num_500':         0,
                     'req_time_avg':    0,
                     'req_time_90th_list': [],
                     'req_time_90th':   0,
                     'req_time_max':    0}
        
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

        # For each "hot" vhost, and for the rest cumulatively, we want to gather:
        # - num hits
        # - num gets
        # - request time: average, max, 90th %
        # - response codes: 200, 300, 400, 500
        
        # Create an 'other' group for non-hot-vhosts
        combined['other'] = self.getBlankStats()

        # Calculate the minimum # of hits that a vhost needs to get broken out
        # from 'other'
        totalHits = 0
        
        #print mydata
        
        for vhost, stats in mydata.iteritems():
            totalHits += stats['num_hits']
        numToBeHot = totalHits * self.percentToBeHot
        
        otherCount = 0

        for vhost, stats in mydata.iteritems():
            # see if this is a 'hot' vhost, or an 'other'
            if stats['num_hits'] >= numToBeHot:
                key = vhost
                combined[key] = self.getBlankStats()
            else:
                otherCount += 1
                key = 'other'
            
            # Calculate statistics over time & number of hits
            if check_time > 0:
                combined[key]['num_hits'] += stats['num_hits'] / check_time
                combined[key]['num_gets'] += stats['num_gets'] / check_time
                combined[key]['num_200']  += stats['num_200']  / check_time
                combined[key]['num_300']  += stats['num_300']  / check_time
                combined[key]['num_400']  += stats['num_400']  / check_time
                combined[key]['num_500']  += stats['num_500']  / check_time
            if stats['num_hits'] > 0:
                combined[key]['req_time_avg'] = stats['req_time_avg'] / stats['num_hits']

            # calculate 90th % request time
            ninetieth_list = stats['req_time_90th_list']
            ninetieth_list.sort()
            num_entries = len(ninetieth_list)
            try:
                combined[key]['req_time_90th'] += ninetieth_list[int(num_entries * 0.9)]
                # Use this check so that we get the biggest value from all 'other's
                if ninetieth_list[-1] > combined[key]['req_time_max']:
                    combined[key]['req_time_max'] = ninetieth_list[-1]
            except IndexError:
                combined[key]['req_time_90th'] = 0
                combined[key]['req_time_max'] = 0

        # The req_time_90th field for the "other" vhosts is now a sum. Need to
        # divide by the number of "other" vhosts
        if otherCount > 0:
            combined['other']['req_time_90th'] /= (otherCount * 1.0)
        else:
            combined['other']['req_time_90th'] = 0

        for vhost, stats in combined.iteritems():
            #print vhost
            #print "\t", stats

            # skip empty vhosts
            if stats['num_hits'] == 0:
                continue

            # package up the data you want to submit
            results.append(GangliaMetricObject('apache_%s_hits' % vhost, stats['num_hits'], units='hps'))
            results.append(GangliaMetricObject('apache_%s_gets' % vhost, stats['num_gets'], units='hps'))
            results.append(GangliaMetricObject('apache_%s_dur_avg' % vhost, stats['req_time_avg'], units='sec'))
            results.append(GangliaMetricObject('apache_%s_dur_90th' % vhost, stats['req_time_90th'], units='sec'))
            results.append(GangliaMetricObject('apache_%s_dur_max' % vhost, stats['req_time_max'], units='sec'))
            results.append(GangliaMetricObject('apache_%s_200' % vhost, stats['num_200'], units='hps'))
            results.append(GangliaMetricObject('apache_%s_300' % vhost, stats['num_300'], units='hps'))
            results.append(GangliaMetricObject('apache_%s_400' % vhost, stats['num_400'], units='hps'))
            results.append(GangliaMetricObject('apache_%s_500' % vhost, stats['num_500'], units='hps'))

        # return a list of metric objects
        return results
