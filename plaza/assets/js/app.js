// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";


// csrf token 
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");

// hooks 
let Hooks = {};
// local storage hook
Hooks.LocalStorage = {
  mounted() {
    this.handleEvent("write", (obj) => this.write(obj))
    this.handleEvent("clear", (obj) => this.clear(obj))
    this.handleEvent("read", (obj) => this.read(obj))
  },

  write(obj) {
    localStorage.setItem(obj.key, obj.data)
  },

  read(obj) {
    var data = localStorage.getItem(obj.key)
    this.pushEvent(obj.event, data)
  },

  clear(obj) {
    localStorage.removeItem(obj.key)
  }
};
// file reader hook 
let base64;
Hooks.FileReader = {
  mounted() {
    const uploadInput = document.getElementById(
      "upload-3-file-input"
    );
    const uploadDisplay = document.getElementById(
      "upload-3-file-display"
    );
    if (base64) {
      uploadDisplay.src = base64;
    }
    uploadInput.addEventListener("change", async () => {
      files = uploadInput.files;
      base64 = await getBase64(files[0]);
      uploadDisplay.src = base64;
    });
  }
};

function getBase64(file) {
  return new Promise(function(resolve, reject) {
    var reader = new FileReader();
    reader.onload = function() { resolve(reader.result); };
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
}

// live socket 
let liveSocket = new LiveSocket("/live", Socket, { params: { _csrf_token: csrfToken }, hooks: Hooks });

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", _info => topbar.show(300));
window.addEventListener("phx:page-loading-stop", _info => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
