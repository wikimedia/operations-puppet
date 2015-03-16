window.onload = function () {
	var stage = jsbench.stage;
	ve.trackSubscribe( 'trace.' + stage + '.', function ( topic ) {
		switch ( topic.split( '.' ).pop() ) {
			case 'enter':
				console.profile( stage );
				break;
			case 'exit':
				console.profileEnd( stage );
				break;
		}
	} );

	// Don't show the welcome dialog.
	localStorage.clear()
	localStorage.setItem( 've-beta-welcome-dialog', 1 );

	// Wait 200ms for any load handlers to run, then start VE.
	setTimeout( function () {
		mw.libs.ve.onEditTabClick( { preventDefault: $.noop } );
	}, 200 );
};

