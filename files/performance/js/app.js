function drawCharts( period ) {
    d3.json( '/coal/v1/metrics?period=' + period, function ( data ) {
        var metric, div, points;

        function preprocessPoint( value, index ) {
            var date = new Date( 1000 * ( data.start + index * data.step ) );
            return { date: date, value: value };
        }

        var graphs = d3.select( '#metrics' )
            .selectAll( 'div' )
            .data( d3.keys( data.points ) );

        graphs.enter()
            .append( 'div' )
            .attr( 'class', 'metric' )
            .attr( 'id', function ( d ) { return d; } );

        graphs.each( function ( metric ) {
            MG.data_graphic( {
                title: metric,
                target: this,
                data: d3.values( data.points[metric ] ).map( preprocessPoint ),
                width: 680,
                height: 200,
                left: 60,
                show_tooltips: false,
                show_rollover_text: false,
            } );
        } );

    } );
}

d3.selectAll( '.nav li:not(.active)' ).on( 'click', function () {
  d3.select( 'li.active' ).classed( 'active', false );
  this.className = 'active';
  drawCharts( this.id );
  d3.event.preventDefault();
} );

drawCharts( 'hour' );
