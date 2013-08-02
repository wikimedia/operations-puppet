#!/usr/bin/python

import argparse
import re
import requests
import sys

# requires pip version or requests. apt version too old

## TODO:
## - make this support warn threshholds

# take command line args of
# -m metric name (graph name)
# -t time period. how far back? (currently minutes back from now)


def parseCommandLine():

    parser = argparse.ArgumentParser(
        description='check_graphite.py [options] some logical expression',
        epilog='Logical expressions are defined as follows: '
        'x=[a:b]: true if value of metric is currently between a and b '
        'xm=[a:b]: true if mean of metric was between a and b over period '
        'x1=[a:b]: true if first deriv of metric was between a and b over period '
        'x2=[a:b]: true if second deriv of metric was between a and b over period '
        'and: logical and '
        'or: logical or '
        '{: logical left paren '
        '}: logical right paren')
    parser.add_argument('-m', '--metric',
                        help='Name of Grpahite metric', required=True)
    parser.add_argument('-t', '--time',
                        help='Number of minutes back from present to check. '
                             ' Default: 5 minutes')
    parser.add_argument('expression', nargs=argparse.REMAINDER,
                        help='Some logical expression')
    args = vars(parser.parse_args())

    return args


def fetchJSON(url):
    # fetch some json, return some json
    # graphite alwasy returns 200, so
    # exit if repsonse is []

    r = requests.get(url)

    if r.json() == []:
        print "Request to graphite host returned no data"
        sys.exit(3)

    return r.json()


# expression:
# x=[a:b]: true if value of metric is currently between a and b
# xm=[a:b]: true if mean of metric was between a and b over period
# x1=[a:b]: true if first deriv of metric was between a and b over period
# x2=[a:b]: true if second deriv of metric was between a and b over period
# and: logical and
# or: logical or
# {: logical left paren
# }: logical right paren
def validateLogic(questionableExpression):

    # keep track of parens to test for equality at end
    rightParen = 0
    leftParen = 0

    for i in range(0, len(questionableExpression)):
        if re.match("and|or", questionableExpression[i]):
            # deal with binary operator at beginning or end
            if i == 0 or i == (len(questionableExpression) - 1):
                print questionableExpression
                print "This is not parseable"  
                sys.exit(3)
            # deal with two binary operators in a row
            # and "and/or }" or "{ and/or" cases
            elif re.match("and|or|\{", questionableExpression[i - 1]) or re.match("and|or|\}", questionableExpression[i + 1]):
                print questionableExpression
                print "This is not parseable"
                sys.exit(3)
        elif questionableExpression[i] == "{":
            ## deal with  { }
            if i != (len(questionableExpression) - 1):
                if questionableExpression[i + 1] == "}":
                    print questionableExpression
                    print "This is not parseable"
                    sys.exit(3)
            leftParen += 1
        elif questionableExpression[i] == "}":
            rightParen += 1
            # left parens must always be equal to or greater than right parens
            if rightParen > leftParen:
                print questionableExpression
                print "This is not parseable"
                sys.exit(3)
        elif re.match("x[m12]?=\[-?\d+(\.\d+)?:-?\d+(\.\d+)?\]", questionableExpression[i]):
            # for any truthy expression, make sure the previous item is
            # beginning of line, binary connector, or left paren
            if not (i == 0 or re.match("and|or|\{", questionableExpression[i - 1])):
                print questionableExpression
                print "This is not parseable"
                sys.exit(3)
            # horrible incatation to get nums our of truthy expression
            bounds = questionableExpression[i][:-1].split("[")[-1].split(":")
            # make sure that both are bounds are convertable to floats
            # i.e. are ints or floats
            try:
                float(bounds[0]) and float(bounds[1])
            except:
                print "Bounds for " + questionableExpression[i] + " are not both numbers"
                sys.exit(3)
            if bounds[0] > bounds[1]:
                print "Bounds for " + questionableExpression[i] + " are not in increasing order"
                sys.exit(3)
        else:
            print questionableExpression[i]
            print "This is not parseable"
            sys.exit(3)
        # at the end of checking, make sure parens are even
        if i == (len(questionableExpression) - 1):
            if rightParen != leftParen:
                print questionableExpression
                print "This is not parseable"
                sys.exit(3)


def bringTheLogic(logicalExpression, dataset):
# NB: this will all break really badly with invalid expressions
# validateLogic must be called at some point before this is used

# start by evaluating everything to true or false
# (it would be better to do this on the fly but this if v 0.1)
# and construct new array of just parens true/false and and/or
# then call recursive logical calculating function
# then return hash of exit code and any metrics created during this

    # eval everything and store in a new array truthyExpression
    # also, store all of the values in returnHash for reporting
    returnHash = { 'exitCode': 2 }
    truthyExpression = []
    for e in logicalExpression:
        if re.match("x[m12]?=\[-?\d+(\.\d+)?:-?\d+(\.\d+)?\]", e):
            numBounds = []
            # horrible incatation to get nums our of e
            bounds = e[:-1].split("[")[-1].split(":")
            for n in bounds:
                numBounds.append(float(n))
            if re.match("x?=\[-?\d+(\.\d+)?:-?\d+(\.\d+)?\]", e):
                dataOut = evalValue(dataset, numBounds[0], numBounds[1])
                truthyExpression.append(dataOut['truth'])
                returnHash['x'] = dataOut['value']
            elif re.match("xm?=\[-?\d+(\.\d+)?:-?\d+(\.\d+)?\]", e):
                dataOut = evalMean(dataset, numBounds[0], numBounds[1])
                truthyExpression.append(dataOut['truth'])
                returnHash['xm'] = dataOut['value']
            elif re.match("x1?=\[-?\d+(\.\d+)?:-?\d+(\.\d+)?\]", e):
                dataOut = evalDeriv(dataset, numBounds[0], numBounds[1])
                truthyExpression.append(dataOut['truth'])
                returnHash['x1'] = dataOut['value']
            elif re.match("x2?=\[-?\d+(\.\d+)?:-?\d+(\.\d+)?\]", e):
                dataOut = evalDeriv(dataset, numBounds[0], numBounds[1], "second")
                truthyExpression.append(dataOut['truth'])
                returnHash['x2'] = dataOut['value']
        else:
            truthyExpression.append(e)

    finalTruth = recurseLogic(truthyExpression)

    if finalTruth == True:
        returnHash['exitCode'] = 0

    return returnHash


def recurseLogic(expression):
# recursive algorithm that parses smallest bit of logic first and works out
# more comments to come
# 
# 

    for i in range(0, len(expression)):
        if expression[i] == "{":
            subI = 0
            smallerList = []
            leftParen = 0
            rightParen = 0
            while leftParen != rightParen:
                if expression[i + subI] == "{":
                    leftParen += 1
                elif expression[i + subI] == "}":
                    rightParen += 1
                smallerList.append(expression[i + subI])
                subI += 1
            recurseLogic(smallerList[1:-1])
        elif (expression[i] == True or expression[i] == False) and len(expression) != 1:
            if expression[i + 1] == 'and':
                if expression[i] == False:
                    return False
                elif expression[i + 2] == True or expression[i + 2] == False:
                    return (expression[i] and expression[i + 2])
                elif expression[i + 2] == "{":
                    subI = 0
                    smallerList = []
                    leftParen = 0
                    rightParen = 0
                    while leftParen != rightParen:
                        if expression[i + subI] == "{":
                            leftParen += 1
                        elif expression[i + subI] == "}":
                            rightParen += 1
                        smallerList.append(expression[i + subI])
                        subI += 1
                    return (expression[i] and recurseLogic(smallerList[1:-1]))
            elif expression[i + 1] == 'or':
                if expression[i] == True:
                    return True
                elif expression[i + 2] == True or expression[i + 2] == False:
                    return (expression[i] or expression[i + 2])
                elif expression[i + 2] == "{":
                    subI = 0
                    smallerList = []
                    leftParen = 0
                    rightParen = 0
                    while leftParen != rightParen:
                        if expression[i + subI] == "{":
                            leftParen += 1
                        elif expression[i + subI] == "}":
                            rightParen += 1
                        smallerList.append(expression[i + subI])
                        subI += 1
                    return (expression[i] or recurseLogic(smallerList[1:-1]))
        else:
            return expression[i]


def calculateMean(valueArray):
# takes a an array of numerical values and returns the mean
    total = 0
    for e in valueArray:
        total += e
    return total / len(valueArray)


def calculateDeriv(timeSeriesArray, scalingFactor=1.0):
# takes in time series array [value, time], spits out time series array
# scaling factor says how the input times are scaled (ex: 60 for seconds)
# scalingFactor should be a float to avoid 0-div errors, so *= 1.0
    scalingFactor *= 1.0
    returnArray = []

    for i in range(0, len(timeSeriesArray) - 1):
        # new time point chosen as endpoint.
        # could also be mid or beginning of interval
        # also scaled by scalingFactor
        timeEndpoint = timeSeriesArray[i + 1][1] / scalingFactor
        changeTime = (timeSeriesArray[i + 1][1] - timeSeriesArray[i][1]) / scalingFactor
        changeValue = (timeSeriesArray[i + 1][0] - timeSeriesArray[i][0]) / changeTime
        returnArray.append([changeValue, timeEndpoint])

    return returnArray


def evalValue(valueArray, lowerBound, upperBound, sloppy=True):
# return hash. keys: 'truth', 'value' 
# truth: true if current value is between bounds, false if not
# value: numerical value from computation
# also, use most recent available value if sloppy set to true (default)

    returnHash = {}
    i = -1
    metricVal = None
    while metricVal is None and i >= -len(valueArray):
        metricVal = valueArray[i][0]
        if sloppy is False:
            break
        i -= 1

    if metricVal is None:
        print "Could not determine current value of" + args['metric']
        sys.exit(3)
    elif lowerBound <= metricVal <= upperBound:
        returnHash['truth'] = True
    else:
        returnHash['truth'] = False

    returnHash['value'] = metricVal
    return returnHash


def evalMean(valueArray, lowerBound, upperBound):
# return hash. keys: 'truth', 'value' 
# truth: true if mean is between bounds, false if not
# value: mean from computation
# error out if there's no data

    returnHash = {}
    numericalArray = []
    for e in valueArray:
        if type(e[0]) == int or type(e[0]) == float:
            numericalArray.append(e[0])

    if len(numericalArray) == 0:
        print "Could not determine mean value of" + args['metric']
        sys.exit(3)

    metricVal = calculateMean(numericalArray)

    if lowerBound <= metricVal <= upperBound:
        returnHash['truth'] = True
    else:
        returnHash['truth'] = False

    returnHash['value'] = metricVal
    return returnHash


def evalDeriv(valueArray, lowerBound, upperBound, degree="first", method="average"):
# calculate degreeth derivative of timeseries data
# return hash. keys: 'truth', 'value' 
# truth: true if mean is between bounds, false if not
# value: mean from computation
# error out if there's no data
# method can be average or instant or max
# average will average the rates of change over the period (default)
# instant will take most recent rate of change

    for e in valueArray:
        if e[0] is None:
            valueArray.remove(e)

    if len(valueArray) == 0 or len(valueArray) == 1:
        print "Could not determine " + degree + " derivative of " + args['metric']
        sys.exit(3)

    # construct array of rates of change
    rocArray = calculateDeriv(valueArray, 60.0)
    if degree == "second":
        rocArray = calculateDeriv(rocArray)

    if method == "average":
        numericalArray = []
        for e in rocArray:
            numericalArray.append(e[0])
        metricVal = calculateMean(numericalArray)
    elif method == "instant":
        metricVal = rocArray[-1][0]
    else:
        print "Could not determine first derivative of " + args['metric'] + " :unknown method"
        sys.exit(3)

    if lowerBound <= metricVal <= upperBound:
        returnHash['truth'] = True
    else:
        returnHash['truth'] = False

    returnHash['value'] = metricVal
    return returnHash


def main():

    ## set some globals
    wmfGraphite = "https://graphite.wikimedia.org"

    ## parse comnmand line and set defaults
    args = parseCommandLine()
    if args["time"] is None:
        args["time"] = 5

    # validate that args[expression] is a wff
    validateLogic(args["expression"])

    ## construct request url
    requestUrl = wmfGraphite + "/render?from=-" + str(args["time"]) + "minutes&until=now&width=500&height=380&target=" + args["metric"] + "&format=json"

    ## get url and grab json
    graphiteJson = fetchJSON(requestUrl)

    jsonDict = graphiteJson[0]
    print jsonDict['datapoints']

    # then determine truth or falsehood
    # also return metric values
    truthinessDict = bringTheLogic(args["expression"], jsonDict['datapoints'])

    # need to also spit out metrics from truthinessDict
    if truthinessDict['exitCond'] == 0:
        print "OK"
        print "METRICS HERE"
        sys.exit(truthinessDict['exitCond'])
    elif truthinessDict['exitCond'] == 2:
        print "CRITICAL"
        print "METRICS HERE"
        sys.exit(truthinessDict['exitCond'])
    else:
        print "UNKNOWN: Something has gone wrong"
        sys.exit(3)


if __name__ == '__main__':
    main()
