/**
 * Ganglia backend for StatsD
 * Author: Ori Livneh
 * Copyright (c) 2013 Wikimedia Foundation <info@wikimedia.org>
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

function logSocketError( err, bytes ) {
    if ( err ) console.log( err );
}

function add( a, b ) {
    return a + b;
}

function sub( a, b ) {
    return a - b;
}

function summarize( ar ) {
    var n = ar.length,
        mid = Math.floor( n / 2 );

    if ( !n ) return false;

    ar.sort( sub );
    return {
        count  : n,
        lower  : ar[n - 1],
        upper  : ar[0],
        mean   : ar.reduce( add ) / n,
        median : n % 2 ? ar[mid] : ( ar[mid-1] + ar[mid] ) / 2,
    };
}

function percentileGroup( ar, p ) {
    var n = ar.length, rank, group;

    if ( n < 1 ) return false;
    rank = Math.round( ( p / 100 * n ) + 0.5 );
    group = ar.slice( 0, rank );

    return {
        count : rank,
        lower : group[rank - 1],
        mean  : group.reduce( add ) / rank,
        upper : group[0],
    };
}

function each( o, callback ) {
    for ( var k in ( o || {} ) ) {
        if ( callback.apply( o, [ k, o[k] ] )  === false ) break;
    }
}


var os = require( 'os' );
var util = require( 'util' );
var dgram = require( 'dgram' );

var Gmetric = require( './gmetric' );
var gmetric = new Gmetric();

var blankGroup = {
    count : 0,
    lower : 0,
    upper : 0,
    mean  : 0,
};
var blankSummary = util._extend( { median: 0 }, blankGroup );

var backendConfig = {
    gangliaGroup   : 'statsd',
    gangliaMetrics : {},
    gangliaPort    : 8649,
    percentThreshold: [ 95 ],
};

var templates = {
    base: {
        hostname : '',
        spoof    : 0,
        units    : '',
        slope    : 'both',
        type     : 'int32',
        tmax     : 60,
        dmax     : 0,
    },
    timer: {
        units: 'ms'
    },
    counter: {
        units: 'count',
    },
    rate: {
        units: 'per second',
    },
};

var socket = dgram.createSocket( 'udp4' );

var ganglia = {
    flushed : Math.floor( new Date() / 1000 ),
    items   : [],
    sent    : 0,
    status  : function ( callback ) {
        callback( null, 'ganglia', 'flushed', ganglia.flushed );
        callback( null, 'ganglia', 'sent', ganglia.sent );
    },
    enqueue : function ( template, name /* , ..., value */ ) {
        var args = Array.prototype.slice.call( arguments, 1 ),
            opts = {};
        util._extend( opts, templates.base );
        util._extend( opts, template || {} );
        util._extend( opts, backendConfig.gangliaMetrics[name] );
        util._extend( opts, {
            value : args.pop(),
            name  : args.join('_'),
        } );
        if ( typeof opts.slope === 'string' ) {
            opts.slope = Gmetric.slope[opts.slope.toLowerCase()];
        }
        ganglia.items.push( opts );
    },
    flush   : function ( timestamp, metrics ) {
        var delta = timestamp - ganglia.flushed;

        if ( delta < 1 )
            return false;

        each( metrics.counters, function ( counter, value ) {
            ganglia.enqueue( templates.counter, counter, value / delta );
            ganglia.enqueue( templates.rate, 'counts', counter, value );
        } );

        each( metrics.timers, function ( timer, values ) {
            var summary = summarize( values ) || blankSummary;

            each( summary, function ( measure, value ) {
                ganglia.enqueue( templates.timer, timer, measure, value );
            } );

            backendConfig.percentThreshold.forEach( function ( p ) {
                var ps = p.toString().replace( '.', '_' ),
                    group = percentileGroup( values, p ) || blankGroup;

                each( group, function ( metric, value ) {
                    ganglia.enqueue( templates.timer, timer, metric, ps, value );
                } );
            } );
        } );

        each( metrics.gauges, ganglia.enqueue );
        ganglia.dispatch();
    },
    dispatch : function () {
        var packed, metric;

        ganglia.flushed = Math.floor( new Date() / 1000 );
        while ( ( metric = ganglia.items.shift() ) !== undefined ) {
            packed = gmetric.pack(metric);
            socket.send( packed.meta, 0, packed.meta.length,
                    backendConfig.gangliaPort, backendConfig.gangliaHost,
                    logSocketError );
            socket.send( packed.data, 0, packed.data.length,
                    backendConfig.gangliaPort, backendConfig.gangliaHost,
                    logSocketError );
            ganglia.sent++;
        }
    },
};

exports.init = function ( start, config, events ) {
    if ( !config || !config.gangliaHost ) {
        return;
    }

    util._extend( backendConfig, config );

    if ( backendConfig.gangliaSpoofHost ) {
        templates.base.hostname = backendConfig.gangliaSpoofHost + ':' + backendConfig.gangliaSpoofHost;
        templates.base.spoof = 1;
    }

    if ( !Array.isArray( backendConfig.percentThreshold ) ) {
        backendConfig.percentThreshold = [ backendConfig.percentThreshold ];
    }

    if ( backendConfig.gangliaMulticast ) {
        socket.bind();
        socket.setBroadcast( true );
        socket.setMulticastTTL( 128 );
        socket.addMembership( backendConfig.gangliaHost );
    }

    templates.base.group = backendConfig.gangliaGroup;
    ganglia.flushed = start;
    events.on( 'flush', ganglia.flush );
    events.on( 'status', ganglia.status );
    return true;
};
