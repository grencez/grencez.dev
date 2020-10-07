"use strict";

main();

function append_chat_message(chat_messages_element, message) {
  let message_element = document.createElement("p");
  message_element.appendChild(document.createTextNode(message));
  chat_messages_element.appendChild(message_element);
}

function copy_button_cb() {
  var copy_field = document.getElementById("copy_field");
  copy_field.select();
  copy_field.setSelectionRange(0, 99999); // For mobile.
  document.execCommand("copy");
}

function main() {
  var chat_messages_element = document.getElementById("chat_messages");

  const url_params = new URLSearchParams(window.location.search);
  const is_webrtc_initiator = !url_params.has("notice_me");

  var peer_connection = new RTCPeerConnection({
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
  });

  var peer_data_channel = null;

  function init_data_channel(c) {
    peer_data_channel = c;
    peer_data_channel.onopen = function() {
      append_chat_message(chat_messages_element, "omg connected");
    }
    peer_data_channel.onmessage = function(ev) {
      append_chat_message(chat_messages_element, "recv: " + ev.data);
    }

    function chat_form_submit_cb() {
      if (!peer_data_channel || peer_data_channel.readyState != "open") {
        return;
      }
      var chat_input_element = document.getElementById("chat_input");
      var message_text = chat_input_element.value;
      if (message_text != "") {
        peer_data_channel.send(message_text);
        append_chat_message(chat_messages_element, "send: " + message_text);
        chat_input_element.value = "";
      }
    }

    document.getElementById("chat_form")
      .addEventListener("submit", chat_form_submit_cb);
  }

  if (is_webrtc_initiator) {
    init_data_channel(peer_connection.createDataChannel("chat_chan"));
  } else {
    document.getElementById("webrtc_answer_input").style.visibility = "hidden";
    peer_connection.addEventListener("datachannel", ev => {
      init_data_channel(ev.channel);
    });
  }

  function ice_candidate_cb(e) {
    if (!e.candidate) {
      return;
    }
    // Don't actually send the peer any candidates.
    // We wait for gathering to complete (in promise_ice_gathered()),
    // then send our connection info to the peer in one shot.
    console.log(e);
  }

  peer_connection.onicecandidate = ice_candidate_cb;

  function promise_ice_gathered() {
    return new Promise(r => {
      peer_connection.addEventListener("icegatheringstatechange", e => {
        if (e.target.iceGatheringState === "complete") {
          r(peer_connection.localDescription);
        }
      });
    });
  }

  function offer_signal_cb(offer) {
    console.log("done!");
    // Provide a link for the peer.
    let url = window.location.href.substring(
      0, window.location.href.length - window.location.search.length);
    url += "?notice_me=" + encodeURIComponent(JSON.stringify(offer));


    document.getElementById("copy_field").value = url;
    append_chat_message(chat_messages_element, "Click the copy button and paste to your friend.");
  }

  function answer_signal_cb(answer) {
    document.getElementById("copy_field").value = JSON.stringify(answer);
    append_chat_message(chat_messages_element, "Click the copy button and paste to your friend.");
  }

  function promise_answer_pasted() {
    let input_element = document.getElementById("webrtc_answer_input");
    return new Promise(r => {
        append_chat_message(chat_messages_element, "your friend should send you some connection info; please paste it above");
      input_element.addEventListener("change", function paste_cb() {
        peer_connection.setRemoteDescription(JSON.parse(input_element.value));
        append_chat_message(chat_messages_element, "trying to connect...");
        input_element.removeEventListener("change", paste_cb);
        r();
      });
    });
  }

  if (is_webrtc_initiator) {
    peer_connection.createOffer()
      .then(offer => peer_connection.setLocalDescription(offer))
      .then(promise_ice_gathered)
      .then(offer_signal_cb)
      .then(promise_answer_pasted)
      .catch(e => {
        append_chat_message(chat_messages_element, "failed");
      });
  } else {
    peer_connection.setRemoteDescription(JSON.parse(
      decodeURIComponent(url_params.get("notice_me"))));
    peer_connection.createAnswer()
      .then(answer => peer_connection.setLocalDescription(answer))
      .then(promise_ice_gathered)
      .then(answer_signal_cb)
      .catch(e => {
        append_chat_message(chat_messages_element, "failed");
      });
  }
}
