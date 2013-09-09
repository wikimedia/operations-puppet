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
 *
 * Ganglia-specific settings (for /etc/statsd/localConfig.js):
 *
 * {
 *   "gangliaHost": "localhost",    // Hostname of Ganglia server
 *   "gangliaPort": 8649,           // UDP port of Ganglia server
 *   "gangliaMulticast": false,     // Use multicast?
 *   "gangliaSpoofHost": "slave",   // Associate metrics w/this hostname
 *   "gangliaGroup": "statsd",      // Default metric group name
 *   "gangliaFilters": [],          // Array of module paths (see below)
 *   "sendMetadataInterval": 60000, // Same as send_metadata_interval
 * }
 *
 * Metric filters
 *
 * If you want to choose which metrics get sent to Ganglia, you may set
 * the "gangliaFilters" configuration to an array of module paths.
 * Each module should export a "filter" function which takes a metric
 * object. The function may modify the metric object or return false to
 * exclude it from Ganglia reporting. For example:
 *
 *   exports.filter = function ( metric ) {
 *     // Exclude counters from Ganglia reporting.
 *     return /count/.test( metric.name ) ? false : metric;
 *   };
 *
 */

function Xdr( bufSize ) {
    this.b = new Buffer( bufSize );
    this.b.fill( 0 );
    this.ptr = 0;
}

Xdr.prototype.pack = function ( type, value ) {
    switch ( type ) {
    case 'int':
        this.b.writeInt32BE( value, this.ptr );
        this.ptr += 4;
        break;
    case 'string':
        this.pack( 'int', value.length );
        this.b.write( value, this.ptr );
        this.ptr += ( ( Buffer.byteLength( value ) + 3 ) & ~0x03 );
        break;
    case 'boolean':
        this.pack( 'int', value ? 1 : 0 );
        break;
    }
};

Xdr.prototype.getBytes = function () {
    return this.b.slice( 0, this.ptr );
};

Xdr.meta = function ( metric ) {
    var xdr = new Xdr( 1024 );

    xdr.pack( 'int', 128 );
    xdr.pack( 'string', metric.hostname );
    xdr.pack( 'string', metric.name );
    xdr.pack( 'boolean', metric.spoof );
    xdr.pack( 'string', metric.type );
    xdr.pack( 'string', metric.name );
    xdr.pack( 'string', metric.units );
    xdr.pack( 'int', metric.slope );
    xdr.pack( 'int', metric.tmax );
    xdr.pack( 'int', metric.dmax );
    xdr.pack( 'int', 1 );
    xdr.pack( 'string', 'GROUP' );
    xdr.pack( 'string', metric.group );
    return xdr.getBytes();
};

Xdr.data = function ( metric ) {
    var xdr = new Xdr( 512 );

    xdr.pack( 'int', 133 );
    xdr.pack( 'string', metric.hostname );
    xdr.pack( 'string', metric.name );
    xdr.pack( 'boolean', metric.spoof );
    xdr.pack( 'string', '%s' );
    xdr.pack( 'string', metric.value.toString() );
    return xdr.getBytes();
};

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

function filterReduce( o, filter ) {
    return filter.filter( o );
}

var os = require( 'os' );
var util = require( 'util' );
var dgram = require( 'dgram' );

var slopes = [ 'zero', 'positive', 'negative', 'both', 'unspecified' ];

var blankGroup = {
    count : 0,
    lower : 0,
    upper : 0,
    mean  : 0,
};
var blankSummary = util._extend( { median: 0 }, blankGroup );

var backendConfig = {
    gangliaGroup         : 'statsd',
    gangliaMetrics       : {},
    gangliaPort          : 8649,
    percentThreshold     : [ 95 ],
    sendMetadataInterval : 60000,
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

var filters = [];

var socket = dgram.createSocket( 'udp4' );


var ganglia = {
    q        : { meta: {}, data: [] },
    flushed  : Math.floor( new Date() / 1000 ),
    sent     : 0,
    status   : function ( callback ) {
        callback( null, 'ganglia', 'flushed', ganglia.flushed );
        callback( null, 'ganglia', 'sent', ganglia.sent );
        callback( null, 'ganglia', 'types', Object.keys( ganglia.q.meta ).length );
    },
    enqueue  : function ( template, name /* , ..., value */ ) {
        var args = Array.prototype.slice.call( arguments, 1 ),
            metric = {};
        util._extend( metric, templates.base );
        util._extend( metric, template || {} );
        util._extend( metric, backendConfig.gangliaMetrics[name] );
        util._extend( metric, {
            value : args.pop(),
            name  : args.join('_'),
        } );
        if ( typeof metric.slope === 'string' ) {
            metric.slope = slopes.indexOf( metric.slope );
        }
        metric = filters.reduce( filterReduce, metric );

        if ( typeof metric === 'object' ) {
            ganglia.q.meta[ metric.name ] = Xdr.meta( metric );
            ganglia.q.data.push( Xdr.data( metric ) );
        }
    },
    flush    : function ( timestamp, metrics ) {
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
    },
    dequeue   : function () {
        var meta, data, keys = Object.keys( ganglia.q.meta ), i = keys.length;

        // metadata packets; emitted repeatedly
        while ( i-- ) {
            meta = ganglia.q.meta[keys[i]];
            socket.send( meta, 0, meta.length,
                backendConfig.gangliaPort, backendConfig.gangliaHost,
                logSocketError );
        }

        if ( !ganglia.q.data.length )
            return;

        // metric packets; emitted once
        ganglia.flushed = Math.floor( new Date() / 1000 );
        while ( ( data = ganglia.q.data.shift() ) !== undefined ) {
            socket.send( data, 0, data.length,
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

    if ( backendConfig.gangliaFilters ) {
        filters.push.apply( filters, backendConfig.gangliaFilters.map( require ) );
    }

    if ( backendConfig.flushInterval < backendConfig.sendMetadataInterval ) {
        backendConfig.sendMetadataInterval = backendConfig.flushInterval;
    }

    if ( backendConfig.flushInterval / 1000 > templates.base.tmax ) {
        templates.base.tmax = backendConfig.flushInterval / 1000;
    }

    if ( backendConfig.gangliaMulticast ) {
        socket.on( 'listening', function () {
            socket.setBroadcast( true );
            socket.setMulticastTTL( 128 );
            socket.addMembership( backendConfig.gangliaHost );
        } );
        socket.bind();
    }

    templates.base.group = backendConfig.gangliaGroup;
    ganglia.flushed = start;
    events.on( 'flush', ganglia.flush );
    events.on( 'status', ganglia.status );

    // StatsD can flush as infrequently as it likes, but we'll emit the
    // metadata packets every 60 seconds or fewer.
    setInterval( ganglia.dequeue, backendConfig.sendMetadataInterval );
    return true;
};
