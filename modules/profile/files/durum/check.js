(function () {
  const testUUID = uuidv4();
  const testTime = new Date().toLocaleTimeString();
  const checkURL = `https://${testUUID}.check.wikimedia-dns.org/check/`;

  fetch(checkURL)
  .then((response) => response.json())
  .then(check => {
    if (check.result === true) {
      const doughService = check.service;
      document.getElementById("check-heading").innerHTML = "&#9745;";
      document.getElementById("check-result").textContent = `Congratulations! You are using Wikidough (${doughService}).`;
    } else {
      document.getElementById("check-heading").innerHTML = "&#9746;";
      document.getElementById("check-result").textContent = "Sorry, you are not using Wikidough.";
    }
  })
  .catch((error) => {
      document.getElementById("check-heading").innerHTML = "&#63;";
      document.getElementById("check-result").textContent = "We were unable to determine if you are using Wikidough.";
  })
  .finally(() => {
      document.getElementById("check-info").textContent = `Tested at ${testTime} with test ID ${testUUID}`;
  });
})();
