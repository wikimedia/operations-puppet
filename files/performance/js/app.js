d3.json( '/coal/v1/metrics', function ( data ) {
    var metric, fragment = document.createDocumentFragment(),
        container = document.getElementsByClassName( 'container' )[0];

    function preprocessPoint( value, index ) {
        var date = new Date( 1000 * ( data.start + index * data.step ) );
        return { date: date, value: value };
    }

    for ( metric in data.points ) {
        var points = d3.values( data.points[metric ] ).map( preprocessPoint ),
            div = document.createElement( 'div' );

        div.id = metric, div.className = 'metric';
        MG.data_graphic( {
            title: metric,
            data: points,
            target: div,
            width: 700,
            height: 200,
            left: 90,
            show_tooltips: false,
            show_rollover_text: false,
        } );

        fragment.appendChild( div );
    }

    container.appendChild( fragment );
} );
