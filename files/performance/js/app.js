/*global d3, MG */
( function () {
    'use strict';

    var defaultPeriod = 'hour';

    function identity( x ) {
        return x;
    }

    function drawCharts( period ) {
        d3.json( '/coal/v1/metrics?period=' + period, function ( data ) {
            var charts = d3.select( '#metrics' )
                .selectAll( 'div' )
                .data( d3.keys( data.points ) );

            charts.enter()
                .append( 'div' )
                .attr( 'class', 'metric' )
                .attr( 'id', identity );

            charts.each( function ( metric ) {
                var points = d3.values( data.points[metric] ).map( function ( value, idx ) {
                    var epochSeconds = data.start + idx * data.step;
                    return { date: new Date( 1000 * epochSeconds ), value: value };
                } );

                MG.data_graphic( {
                    title: metric,
                    target: this,
                    data: points,
                    width: 680,
                    height: 200,
                    left: 60,
                    show_tooltips: false,
                    show_rollover_text: true
                } );
            } );
        } );
    }

    function selectTab( tab ) {
        if ( d3.select( tab ).classed( 'active' ) ) {
            return;
        }
        d3.select( 'li.active' ).classed( 'active', false );
        tab.className = 'active';
        drawCharts( tab.id );
    }

    d3.selectAll( '.nav li' ).on( 'click', function () {
        selectTab( this );
    } );

    function init() {
        // Handle permalink
        if ( /^#!\/./.test( location.hash ) ) {
            var id = location.hash.slice( 3 );
            // In case of default, call drawCharts() directly.
            // Callling selectTab() would return early without drawing.
            if ( id !== defaultPeriod ) {
                var navItem = document.getElementById( id );
                if ( navItem ) {
                   selectTab( navItem );
                   return;
                }
            }
        }

        // Default
        drawCharts( defaultPeriod );
    }

    init();
} () );
