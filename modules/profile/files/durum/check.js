(function () {
  const testUUID = uuidv4();
  const testTime = new Date().toLocaleTimeString();
  const checkURL = `https://${testUUID}.check.wikimedia-dns.org/check/`;
  const dcToLoc = {"eqiad": "US (Virginia)", "codfw": "US (Texas)", "esams": "The Netherlands",
                   "ulsfo": "US (California)", "eqsin": "Singapore", "drmrs": "France"}

  fetch(checkURL)
  .then((response) => response.json())
  .then(check => {
    if (check.wikidough === true) {
      const doughService = check.service;
      if (doughService === "doh") {
        document.getElementById("check-doh-warning").style.visibility = "visible";
      }
      const description = doughService === "doh" ? "DoH (DNS-over-HTTPS)" : "DoT (DNS-over-TLS)";

      document.getElementById("check-heading").innerHTML = "&#9745;";
      document.getElementById("check-result").textContent = "Congratulations! You are using Wikidough.";
      document.getElementById("check-result").style.color = 'green';
      document.getElementById("check-service").textContent = `Connected over ${description} in ${dcToLoc[check.site]}`;
    } else {
      document.getElementById("check-heading").innerHTML = "&#9746;";
      document.getElementById("check-result").textContent = "Sorry, you are not using Wikidough.";
      document.getElementById("check-result").style.color = 'red';
      document.getElementById("check-service").textContent = "Not connected over DoH or DoT";
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
