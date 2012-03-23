import os, math, random, time, tempfile
from datetime import datetime, timedelta

def ask(question,options=["Yes","No"]):
    answer = ""
    if len(options) < 3:
        question += ' ('
        for option in options:
            question += option[:1] + ' ' + option + ', '
        else:
            question = question[:-2] + ')'
        return input(question).lower()[:1]
    else:
        print(question)
        for option in options:
            print ('\t',option[:1],':',option)
        return input('Please select an option:').lower()[:1]                

def mkdirs(file):
    dir = os.path.dirname(file)
    if not os.path.exists(dir):
        os.makedirs(dir)
        
def removeFile(file):
    if os.path.exists(file):
        os.remove(file)

def write(file, blob, mode='wb'):
    _write(file, blob, mode)

def _write(file, blob, mode):
    f = open(file, mode)
    f.write(blob)
    f.close()

def fileName(path):
    path, file = os.path.split(path)
    return file

def normalizePath(path):
    return path.replace('\\','/')

def createTempFile(content=""):
    f = tempfile.NamedTemporaryFile(mode="w+",delete=False)
    f.write(content)
    f.close()
    return f.name

def createTempDir():
    return tempfile.mkdtemp()

def getTempDirName():
    return os.path.join(tempfile.gettempdir(),"gitcc_sync_" + str(random.randrange(1000000,9999999)))

class time_util():
    
    class TZ_INFO:
        """ Implementation of the singleton TZ_INFO class """
        def __init__(self):
            self.offset_in_seconds = time.timezone
            if time.daylight != 0:
                self.offset_in_seconds = time.altzone
            self.offset_hours = str(math.floor(abs(self.offset_in_seconds/60/60)))
            self.offset_mins = str(int(abs(self.offset_in_seconds/60/60%1 * 60))) 
        def __str__(self):
            hours = self.offset_hours
            mins = self.offset_mins
            if int(hours) < 10:
                hours = '0' + hours
            if int(mins) < 10:
                mins = '0' + mins
            if time.timezone < 0:
                hours = '+' + hours
            else:
                hours = '-' + hours
            return hours + ':' + mins            
    tz_info = TZ_INFO()

    def __init__(self):
        if time_util.tz_info is None:
            time_util.tz_info = time_util.TZ_INFO()
    
    @classmethod       
    def getOffsetAsString(cls):
        cls()
        return cls.tz_info.__string__()
        
    # Returns a time_stuct (i.e. date) given a valid string
    # that is formated using @format
    #
    # If the date string includes a valid UTC offset, the date is converted to the 
    # current time-zone using the offset make it easy to use in comparisons 
    # 
    # NOTE: Daylight savings time rules are applied when calculating the correct TZ offset.
    @classmethod
    def parseDate(cls,datestr,format):
        cls()
        def calcOffset(utc):
            utc = utc.replace(":",""); # remove ':'
            if len(utc) > 3:
                utcHours = float(utc[:-2])
                utcMinutes = float(utc[-2:])
            else: 
                utcHours = float(utc)
                utcMinutes = 0
            if utcHours < 0:
                offset = utcHours - utcMinutes/60 
            else:
                offset = utcHours + utcMinutes/60
            return cls.tz_info.offset_in_seconds/60/60 + offset
    
        if len(datestr) > 22: # UTC offset is -HH:MM (happens on windows 2003 server) 
            offset = calcOffset(datestr[-6:])
            datestr = datestr[:-6]
        elif len(datestr) > 19: # UTC offset is -HH
            offset = calcOffset(datestr[-3:])
            datestr = datestr[:-3]
        else: # No UTC offset given
            offset = 0
        return datetime.strptime(datestr, format) + timedelta(hours=-offset)            
    
        # TODO: Fix this so it doesn't use hard          

    @classmethod
    def addTZOffset(cls,date,format):
        return datetime.strftime(date,format) + str(cls.tz_info)

    def normalizePath(self,path):
        # TODO: Add os check and return correct file seperator
        return path.replace("/","\\")
    

 
