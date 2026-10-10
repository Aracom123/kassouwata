var isPaymentPage = false;
var redirectUrl;
var iPaymoneySdk;
var callbackUrl;

window.onCloseIpayCheckout = function onCloseIpayCheckout() {
  if (isPaymentPage === true) {
    document.querySelector(".ipaymoney-payment-page").remove();
    isPaymentPage = false;
  }
}

window.addEventListener('message', function(message) {
  if (message.data.type == "closeModal") onCloseIpayCheckout();
  if (message.data.type == "payment.response") {
    if (redirectUrl && message.data.other.status == 'succeeded') window.location.replace(`${redirectUrl}&transactionId=${message.data.other.reference}&status=${message.data.other.status}&amount=${message.data.other.amount}`);
    if (callbackUrl) {
      if (iPaymoneySdk == "woocommerce") {
        window.location.replace(`${callbackUrl}&external_reference=${message.data.other.externalReference}&status=${message.data.other.status}&amount=${message.data.other.amount}`)
      } else {
        var myHeaders = new Headers();
        myHeaders.append("Content-Type", "application/json");
        var raw = JSON.stringify(message.data.other);
        var requestOptions = {
          method: 'POST',
          headers: myHeaders,
          body: raw
        };
        fetch(callbackUrl, requestOptions)
          .then(response => response.json())
          .then(result => console.log(result))
          .catch(error => console.log('error', error));
      }
    }
  }
});

document.addEventListener("DOMContentLoaded", function(event) {
  var ipaymoneyOpenButton = document.querySelectorAll(".ipaymoney-button");

  for (var i = 0; i < ipaymoneyOpenButton.length; i++) {
    var buttonId = (Math.random() + 1).toString(6);
    ipaymoneyOpenButton[i].setAttribute('data-id', buttonId);
  }

  for (var i = 0; i < ipaymoneyOpenButton.length; i++) {
    ipaymoneyOpenButton[i].addEventListener("click", ((e) => {
      var key = e.target.dataset.key;
      var amount = e.target.dataset.amount;
      var environement = e.target.dataset.environement;
      var transactionId = e.target.dataset.transactionId;
      redirectUrl = e.target.dataset.redirectUrl;
      callbackUrl = e.target.dataset.callbackUrl;
      iPaymoneySdk = e.target.dataset.sdk;

      var myHeaders = new Headers();
      myHeaders.append("Content-Type", "application/json");

      var raw = JSON.stringify({
        key: key,
        amount: amount,
        environement: environement,
        transaction_id: transactionId,
        parent_domaine: window.location.origin
      });

      var requestOptions = {
        method: 'POST',
        headers: myHeaders,
        body: raw
      };

      fetch('https://i-pay.money/api/sdk/payment_pages/create_payment_token', requestOptions)
        .then(response => response.json())
        .then(data => {
          var token = data.token;

          var iPayDiv = document.createElement("div");
          document.body.appendChild(iPayDiv);
          iPayDiv.className = "ipaymoney-payment-page";
          iPayDiv.setAttribute("style", "position: fixed; top: 0; left: 0; width: 100%; height: 100%; background-color: rgba(0, 0, 0, 0.50); z-index: 999999;");

          var iPayIframeContainer = document.createElement("div");
          iPayDiv.appendChild(iPayIframeContainer);
          iPayIframeContainer.setAttribute("style", "position: relative; width: 100%; height: 100%; margin: 0 auto;");

          var iPayLoader = document.createElement('div');
          var spinKeyframes = [
            { transform: 'rotate(0deg)' },
            { transform: 'rotate(360deg)' }
          ];
          var spinTiming = {
            duration: 2000,
            iterations: Infinity,
            easing: 'linear'
          };

          iPayLoader.animate(spinKeyframes, spinTiming);
          iPayLoader.setAttribute("style", `
            position: absolute;
            width: 100px;
            height: 100px;
            top: 50%;
            left: 50%;
            -webkit-transform: translate(-50%, -50%);
            transform: translate(-50%, -50%);
            z-index: 9999999;
            border: 4px solid #fdffde;
            border-radius: 50%;
            border-top: 4px solid #a6bd2e;
            border-bottom: 4px solid #a5be2e;
            width: 50px;
            height: 50px;
            -webkit-animation: spin 2s linear infinite;
            animation: spin 2s linear infinite;
          `);
          iPayIframeContainer.appendChild(iPayLoader);

          var iPayIframe = document.createElement("iframe");
          iPayIframeContainer.appendChild(iPayIframe);
          iPayIframe.setAttribute("style", "display: none");
          iPayIframe.onload = function() {
            iPayIframe.setAttribute("style", "border: 0; width: 100%; display: block;");
            iPayLoader.setAttribute("style", "display: none");
          };
          iPayIframe.onerror = function() {
            console.log("Something wrong happened");
          };

          var sdkUrl = `https://i-pay.money/api/sdk/payment_pages?token=${token}`;

          iPayIframe.src = sdkUrl;
          iPayIframe.width = "100%";
          iPayIframe.height = "100%";
          iPayIframe.frameborder = "0";
          iPayIframe.id = "i-pay-frame";
          iPayIframe.target = "_parent";
          isPaymentPage = true;
        })
        .catch(error => console.log('error', error));
    }));
  }
});