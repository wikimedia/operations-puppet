(function( $, app, i18n ) {

	var ui = app.ns("ui");
	var data = app.ns("data");

	var StructuredQuery = ui.AbstractQuery.extend({
		defaults: {
			cluster: null  // (required) instanceof app.services.Cluster
		},
		init: function(parent) {
			this._super();
			this.selector = new ui.IndexSelector({
				onIndexChanged: this._indexChanged_handler,
				base_uri: this.config.base_uri
			});
			this.el = $(this._main_template());
			this.out = this.el.find("DIV.uiStructuredQuery-out");
			this.attach( parent );
		},
		
		_indexChanged_handler: function(index) {
			this.filter && this.filter.remove();
			this.filter = new ui.FilterBrowser({
				cluster: this.config.cluster,
				base_uri: this.config.base_uri,
				index: index,
				onStaringSearch: function() { this.el.find("DIV.uiStructuredQuery-out").text( i18n.text("General.Searching") ); this.el.find("DIV.uiStructuredQuery-src").hide(); }.bind(this),
				onSearchSource: this._searchSource_handler,
				onJsonResults: this._jsonResults_handler,
				onTableResults: this._tableResults_handler
			});
			this.el.find(".uiStructuredQuery-body").append(this.filter);
		},
		
		_jsonResults_handler: function(results) {
			this.el.find("DIV.uiStructuredQuery-out").empty().append( new ui.JsonPretty({ obj: results }));
		},
		
		_tableResults_handler: function(results, metadata) {
			// hack up a QueryDataSourceInterface so that StructuredQuery keeps working without using an es.Query object
			var qdi = new data.QueryDataSourceInterface({ metadata: metadata, query: new data.Query() });
			var tab = new ui.Table( {
				store: qdi,
				height: 400,
				width: this.out.innerWidth()
			} ).attach(this.out.empty());
			qdi._results_handler(qdi.config.query, results);
		},
		
		_showRawJSON : function() {
			if($("#rawJsonText").length === 0) {
				var hiddenButton = $("#showRawJSON");
				var jsonText = $({tag: "P", type: "p", id: "rawJsonText"});
				jsonText.text(hiddenButton[0].value);
				hiddenButton.parent().append(jsonText);
			}
		},
		
		_searchSource_handler: function(src) {
			var searchSourceDiv = this.el.find("DIV.uiStructuredQuery-src");
			searchSourceDiv.empty().append(new app.ui.JsonPretty({ obj: src }));
			if(typeof JSON !== "undefined") {
				var showRawJSON = $({ tag: "BUTTON", type: "button", text: i18n.text("StructuredQuery.ShowRawJson"), id: "showRawJSON", value: JSON.stringify(src), onclick: this._showRawJSON });
				searchSourceDiv.append(showRawJSON);
			}
			searchSourceDiv.show();
		},
		
		_main_template: function() {
			return { tag: "DIV", children: [
				this.selector,
				{ tag: "DIV", cls: "uiStructuredQuery-body" },
				{ tag: "DIV", cls: "uiStructuredQuery-src", css: { display: "none" } },
				{ tag: "DIV", cls: "uiStructuredQuery-out" }
			]};
		}
	});

	ui.StructuredQuery = ui.Page.extend({
		init: function() {
			this.q = new StructuredQuery( this.config );
			this.el = this.q.el;
		}
	});

})( this.jQuery, this.app, this.i18n );
