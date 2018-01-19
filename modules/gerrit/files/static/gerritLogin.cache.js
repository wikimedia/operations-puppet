// Copyright (C) 2018 typo3
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

{
  ("use strict");
  LoginForm = (function() {
    var form = null;
    var usernameField = null;
    var passwordField = null;

    function init() {
      form = document.getElementById("login_form");
      if (form) {
        document.body.className = "loginParent";
      }
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
        if (body && body.length) {
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

    if (document.getElementById("login_form")) {
      window.onload = function() {
        init();
      };
    }
    return this;
  })();
}
