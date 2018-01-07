{
  ("use strict");
  LoginForm = (function() {
    var form = null;
    var usernameField = null;
    var passwordField = null;

    function init() {
      form = document.getElementById("login_form");
      usernameField = document.getElementById("f_user");
      passwordField = document.getElementById("f_pass");

      showBody();
      if (form && form.length > 0) {
        renderPlaceholder();
        renderErrorMessage();
      }
    }

    /**
     * To prevent that the user sees the old UI and get the flickering we hide
     * the body and make it visible again.
     *
     * @return {void}
     */
    function showBody() {
      setTimeout(function() {
        var body = document.getElementsByTagName("body");
        console.log(body);
        if (body.length) {
          body[0].style.visibility = "visible";
        }
      }, 500);
    }

    /**
     * The gerrit markup has no real placeholder. So we need to grap the table
     * headline and define this as placeholder.
     *
     * @return {void}
     */
    function renderPlaceholder() {
      var usernameHeader = usernameField.parentNode.previousSibling;
      var passwordHeader = passwordField.parentNode.previousSibling;

      if (usernameHeader) {
        usernameField.placeholder = usernameHeader.textContent.length
          ? usernameHeader.textContent
          : "User";
      }

      if (passwordHeader) {
        passwordField.placeholder = passwordHeader.textContent.length
          ? passwordHeader.textContent
          : "Password";
      }
    }

    /**
     * The error message will be rendered outside the login form.
     * So this method will move the markup after the password field.
     *
     * @return {void}
     */
    function renderErrorMessage() {
      var errorMessageContainer = document.getElementById("error_message");

      if (errorMessageContainer && passwordField.parentNode) {
        passwordField.parentNode.appendChild(errorMessageContainer);
      }
    }

    window.onload = function() {
      init();
    };
    return this;
  })();
}
