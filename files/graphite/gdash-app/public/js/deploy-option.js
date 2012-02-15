/* toggle display of code deploys */

!function( $ ){

  $(function () {
    $('#deploy').bind("click", function(){
        var href = window.location.href;
        if (href.match( /deploys$/ )) {
            var cap = /^(.*)(deploys)/;
            var match = cap.exec(href);
            window.location = match[1];
        }
        else {
            window.location = href + "deploys";
        }
    });
  })

}( window.jQuery || window.ender );
