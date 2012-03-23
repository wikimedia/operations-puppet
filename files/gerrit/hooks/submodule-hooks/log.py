import os, sys, logging, logging.handlers
from util import mkdirs


#########################################
# Setup Logging
#########################################

LOG_FILENAME = sys.path[0] + '/log/change-merge-hook-output.log'
mkdirs(LOG_FILENAME)

formatter = logging.Formatter("%(asctime)s %(levelname)s %(name)s >> %(message)s")

# Add the log message handler to the logger
fileHandler = logging.handlers.RotatingFileHandler(
              LOG_FILENAME, maxBytes=2400000, backupCount=5)
fileHandler.setFormatter(formatter)

consoleHandler = logging.StreamHandler()
consoleHandler.setLevel(logging.DEBUG)
consoleHandler.setFormatter(formatter)

# Set up a specific logger with our desired output level
def getLogger(loggerName, level=logging.DEBUG):
    logger = logging.getLogger(loggerName)
    logger.setLevel(level)
    logger.addHandler(consoleHandler)
    logger.addHandler(fileHandler)
    return logger



