# -*- coding: utf-8 -*-
###
###  This plugin for logtailer will crunch WMF packet loss logs and return:
###    * average percent loss
###    * ninetieth percentile loss
###  It will throw out
###    * packet loss numbers greater than 98%
###    * large margins of error
###    * margins of error are greater than percent packet loss
###  Note that this plugin depends on a certain apache log format, documented in
##   __init__.

import time
import threading
import re

# local dependencies
from ganglia_logtailer_helper import GangliaMetricObject
from ganglia_logtailer_helper import LogtailerParsingException, LogtailerStateException

class PacketLossLogtailer(object):
    # only used in daemon mode
    period = 30
    def __init__(self):
        '''This function should initialize any data structures or variables
        needed for the internal state of the line parser.'''
        self.reset_state()
        self.lock = threading.RLock()
        # this is what will match the packet loss lines
        # packet loss format :
        # %[%Y-%m-%dT%H:%M:%S]t %server lost: (%percentloss +/- %margin)
        # [2011-10-26T21:20:25] sq86.wikimedia.org lost: (3.61446 +/- 19.67462)%
        # match keys: date, server, percentloss, margin

        self.reg = re.compile ('^\[(?P<date>[^]]+)\] (?P<server>[^ ]+) lost: \((?P<percentloss>[^ ]+) \+\/- (?P<margin>[^)]+)\)%')
        # assume we're in daemon mode unless set_check_duration gets called
        self.dur_override = False

    # example function for parse line
    # takes one argument (text) line to be parsed
    # returns nothing
    def parse_line(self, line):
        '''This function should digest the contents of one line at a time,
        updating the internal state variables.'''
        self.lock.acquire()
        try:
            regMatch = self.reg.match(line)
            if regMatch:
                linebits = regMatch.groupdict()
                self.num_hits+=1
                # capture data
                percentloss = float(linebits['percentloss'])
                margin = float(linebits['margin'])
                # store for 90th % and average calculations
                # on ssl servers, sequence numbers are out of order.
                # http://rt.wikimedia.org/Ticket/Display.html?id=1616
                if( ( margin <= 20 ) and ( percentloss <= 98 ) ):
                    self.percentloss_list.append(percentloss)
            else:
                raise LogtailerParsingException, "regmatch failed to match"

        except Exception, e:
            self.lock.release()
            raise LogtailerParsingException, "regmatch or contents failed with %s" % e
        self.lock.release()
    # example function for deep copy
    # takes no arguments
    # returns one object
    def deep_copy(self):
        '''This function should return a copy of the data structure used to
        maintain state.  This copy should different from the object that is
        currently being modified so that the other thread can deal with it
        without fear of it changing out from under it.  The format of this
        object is internal to the plugin.'''
        myret = dict(percentloss_list=self.percentloss_list
                    )
        return myret
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
        self.num_hits = 0
        self.percentloss_list = list()
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
        if( self.dur_override ):
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
        # if number of log lines is 0, then return no data
        if ( self.num_hits == 0):
            return list()

        self.lock.acquire()
        try:
            mydata = self.deep_copy()
            check_time = self.get_check_duration()
            self.reset_state()
            self.lock.release()
        except LogtailerStateException, e:
            # if something went wrong with deep_copy or the duration, reset and continue
            self.reset_state()
            self.lock.release()
            raise e

        # calculate 90th % and average request times
        percentloss_list = mydata['percentloss_list']
        percentloss_list.sort()
        num_entries = len(percentloss_list)
        if (num_entries != 0 ):
            packetloss_90th = percentloss_list[int(num_entries * 0.9)]
            packetloss_ave = sum(percentloss_list) / len(percentloss_list)
        else:
            # in this event, all data was thrown out in parse_line
            packetloss_90th = 99
            packetloss_ave = 99
        # package up the data you want to submit
        # setting tmax to 960 seconds as data may take as long as 15 minutes to be processed
        packetloss_ave_metric = GangliaMetricObject( 'packet_loss_average', packetloss_ave, units='%', tmax=960 )
        packetloss_90th_metric = GangliaMetricObject( 'packet_loss_90th', packetloss_90th, units='%', tmax=960 )

        # return a list of metric objects
        return [ packetloss_ave_metric, packetloss_90th_metric, ]