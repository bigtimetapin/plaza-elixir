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
import "jimp";

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
let frontMockUrl; let backMockUrl;
let frontMockPng; let backMockPng;
let frontDesignPng; let backDesignPng;
const aspectRatio = 29.0 / 42.0;
Hooks.FileReader = {
  mounted() {
    console.log("right now");
    this.handleEvent("front-upload-cancel", (_) => {
      frontMockUrl = "png/mockup-front.png";
    });
    this.handleEvent("back-upload-cancel", (_) => {
      backMockUrl = "png/mockup-back.png";
    });
    const frontInput = document.getElementById(
      "plaza-file-input-front"
    );
    const backInput = document.getElementById(
      "plaza-file-input-back"
    );
    const frontDisplay = document.getElementById(
      "plaza-file-display-front"
    );
    const backDisplay = document.getElementById(
      "plaza-file-display-back"
    );
    if (frontInput) {
      frontInput.addEventListener("change", async () => {
        const files = frontInput.files;
        if (files.length == 1) {
          const file = files[0];
          const designUrl = URL.createObjectURL(file);
          frontDisplay.src = designUrl;
          Jimp.read(designUrl)
            .then(async (image) => {
              let width = image.bitmap.width;
              const height = image.bitmap.height;
              width = Math.trunc(aspectRatio * height);
              image.crop(0, 0, width, height);
              frontDesignPng = image;
              /////////
              Jimp.read("./../png/mockup-front.png")
                .then(async (mock) => {
                  const ratio = 0.37 * mock.bitmap.width / image.bitmap.width;
                  image.scale(ratio);
                  mock.composite(image, 393, 450);
                  frontMockPng = mock;
                  const base64 = await mock.getBase64Async(Jimp.AUTO);
                  frontDisplay.src = base64;
                  frontMockUrl = base64;
                })
            })
            .catch((err) => {
              console.log(err);
            });
          this.pushEvent(
            "front-upload-change",
            file.name
          );
        }
      });
    }
    if (backInput) {
      console.log("now")
      backInput.addEventListener("change", async () => {
        const files = backInput.files;
        if (files.length == 1) {
          const file = files[0];
          const designUrl = URL.createObjectURL(file);
          backDisplay.src = designUrl;
          Jimp.read(designUrl)
            .then(async (image) => {
              let width = image.bitmap.width;
              const height = image.bitmap.height;
              width = Math.trunc(aspectRatio * height);
              image.crop(0, 0, width, height);
              backDesignPng = image;
              /////////
              Jimp.read("./../png/mockup-back.png")
                .then(async (mock) => {
                  const ratio = 0.37 * mock.bitmap.width / image.bitmap.width;
                  image.scale(ratio);
                  mock.composite(image, 393, 450);
                  backMockPng = mock;
                  const base64 = await mock.getBase64Async(Jimp.AUTO);
                  backDisplay.src = base64;
                  backMockUrl = base64;
                })
            })
            .catch((err) => {
              console.log(err);
            });
          this.pushEvent(
            "back-upload-change",
            file.name
          );
        }
      });
    }
  }
};
// file display hook 
Hooks.FileDisplay = {
  mounted() {
    console.log("here");
    const frontDisplay = document.getElementById(
      "plaza-file-display-front"
    );
    const backDisplay = document.getElementById(
      "plaza-file-display-back"
    );
    if (frontMockUrl && frontDisplay) {
      console.log("here");
      frontDisplay.src = frontMockUrl;
    };
    if (backMockUrl && backDisplay) {
      backDisplay.src = backMockUrl;
    };
  }
}

// S3 file uploader 
Hooks.S3FileUploader = {
  mounted() {
    this.handleEvent("upload", (obj) => {
      console.log(obj);
      let formData = new FormData();
      Object.entries(obj.fields).forEach(
        ([key, val]) => formData.append(key, val)
      );
      formData.append("file", png);
      let xhr = new XMLHttpRequest();
      xhr.upload.addEventListener("progress", (event) => {
        if (event.lengthComputable) {
          let percent = Math.round((event.loaded / event.total) * 100);
          console.log(percent);
        }
      });
      xhr.open("POST", obj.url, true);
      xhr.send(formData);
    })
  },
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
