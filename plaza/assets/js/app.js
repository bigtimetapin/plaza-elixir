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
// infinite scroll hook 
Hooks.LandingInfiniteScroll = {
  mounted() {
    this.scroll(this)
  },
  updated() {
    this.scroll(this)
  },
  scroll(that) {
    const options = {
      root: document.querySelector("#landing-scroll"),
      threshold: 0.75,
    };
    let callback = (entries, _observer) => {
      entries.forEach((entry) => {
        console.log(entry);
        if (entry.isIntersecting) {
          console.log(entry.target.id);
          if (entry.target.id == "landing-scroll-first") {
            that.pushEvent("uncurated-cursor-before", {});
          }
          if (entry.target.id == "landing-scroll-last") {
            that.pushEvent("uncurated-cursor-after", {});
          }
        }
      });
    };
    const observer = new IntersectionObserver(callback, options);
    const first = document.querySelector("#landing-scroll-first");
    if (first) {
      observer.observe(first);
    }
    const last = document.querySelector("#landing-scroll-last");
    if (last) {
      observer.observe(last);
    }
  },
}
// local storage hook
Hooks.LocalStorage = {
  mounted() {
    this.handleEvent("write", (obj) => this.write(obj));
    this.handleEvent("clear", (obj) => this.clear(obj));
    this.handleEvent("read", (obj) => this.read(obj));
  },
  write(obj) {
    localStorage.setItem(obj.key, obj.data);
  },
  read(obj) {
    const data = localStorage.getItem(obj.key);
    this.pushEvent(obj.event, data);
  },
  clear(obj) {
    localStorage.removeItem(obj.key);
  }
};
// logo reader hook 
let logoBase64; let logoPng; let logoFileName;
Hooks.LogoFileReader = {
  mounted() {
    const logoInput = document.getElementById(
      "plaza-logo-input"
    );
    this.handleEvent("logo-upload-cancel", (_) => {
      logoBase64 = logoPng = logoFileName = null;
    });
    logoInput.addEventListener("change", async () => {
      const files = logoInput.files;
      if (files.length == 1) {
        const file = files[0];
        logoFileName = crypto.randomUUID();
        const url = URL.createObjectURL(file);
        Jimp.read(url)
          .then(async (image) => {
            logoPng = image;
            logoBase64 = await image.getBase64Async(Jimp.AUTO);
            this.pushEvent(
              "logo-upload-change",
              logoFileName
            );
          });
      }
    });
  }
}
// logo display hook 
Hooks.LogoDisplay = {
  mounted() {
    console.log("here");
    const display = document.getElementById(
      "plaza-logo-display"
    );
    display.src = logoBase64;
  }
}
window.addEventListener("phx:plaza-logo-display-s3-url", (obj) => {
  console.log("and here");
  const display = document.getElementById(
    "plaza-logo-display"
  );
  if (display) {
    display.src = obj.detail.url
  }
  logoBase64 = obj.detail.url;
});
// file reader hook 
let frontMockUrl; let backMockUrl;
let frontMockPng; let backMockPng;
let frontDesignPng; let backDesignPng;
let frontFileName; let backFileName;
const aspectRatio = 29.0 / 42.0;
const defaultFrontMockUrl = "./../png/mockup-front.png";
const defaultBackMockUrl = "./../png/mockup-back.png";
Hooks.FileReader = {
  mounted() {
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
    this.handleEvent("front-upload-cancel", (_) => {
      frontMockUrl = defaultFrontMockUrl;
      frontDisplay.src = frontMockUrl;
    });
    this.handleEvent("back-upload-cancel", (_) => {
      backMockUrl = defaultBackMockUrl;
      backDisplay.src = backMockUrl;
    });
    if (frontInput) {
      frontInput.addEventListener("change", async () => {
        const files = frontInput.files;
        if (files.length == 1) {
          const file = files[0];
          frontFileName = crypto.randomUUID();
          const designUrl = URL.createObjectURL(file);
          Jimp.read(designUrl)
            .then(async (image) => {
              let width = image.bitmap.width;
              const height = image.bitmap.height;
              width = Math.trunc(aspectRatio * height);
              image.crop(0, 0, width, height);
              frontDesignPng = image;
              /////////
              Jimp.read(defaultFrontMockUrl)
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
            frontFileName
          );
        }
      });
    }
    if (backInput) {
      backInput.addEventListener("change", async () => {
        const files = backInput.files;
        if (files.length == 1) {
          const file = files[0];
          backFileName = crypto.randomUUID();
          const designUrl = URL.createObjectURL(file);
          Jimp.read(designUrl)
            .then(async (image) => {
              let width = image.bitmap.width;
              const height = image.bitmap.height;
              width = Math.trunc(aspectRatio * height);
              image.crop(0, 0, width, height);
              backDesignPng = image;
              /////////
              Jimp.read(defaultBackMockUrl)
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
            backFileName
          );
        }
      });
    }
  }
};
// file display hook 
Hooks.FileDisplay = {
  mounted() {
    const frontDisplay = document.getElementById(
      "plaza-file-display-front"
    );
    const backDisplay = document.getElementById(
      "plaza-file-display-back"
    );
    if (frontMockUrl && frontDisplay) {
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
    this.handleEvent("upload", async (obj) => {
      if (obj.side === "front") {
        const designPng = await jimpToPng(frontDesignPng, frontFileName);
        uploadToS3(this, "front-design", obj.url, obj.design_fields, designPng);
        const mockFileName = "mock_" + frontFileName;
        const mockPng = await jimpToPng(frontMockPng, mockFileName);
        uploadToS3(this, "front-mock", obj.url, obj.mock_fields, mockPng);
      }
      if (obj.side === "back") {
        const designPng = await jimpToPng(backDesignPng, backFileName);
        uploadToS3(this, "back-design", obj.url, obj.design_fields, designPng);
        const mockFileName = "mock_" + backFileName;
        const mockPng = await jimpToPng(backMockPng, mockFileName);
        uploadToS3(this, "back-mock", obj.url, obj.mock_fields, mockPng);
      }
      if (obj.side === "logo") {
        const png = await jimpToPng(logoPng, logoFileName);
        uploadToS3(this, "logo", obj.url, obj.fields, png);
      }
    })
  },
};

function uploadToS3(that, side, url, fields, png) {
  let formData = new FormData();
  Object.entries(fields).forEach(
    ([key, val]) => formData.append(key, val)
  );
  formData.append("file", png);
  let xhr = new XMLHttpRequest();
  xhr.upload.addEventListener("progress", (event) => {
    if (event.lengthComputable) {
      let percent = Math.round((event.loaded / event.total) * 100);
      console.log(percent);
      if (percent === 100) {
        that.pushEvent(
          "s3-upload-complete",
          side
        );
      }
    }
  });
  xhr.open("POST", url, true);
  xhr.send(formData);
}

async function jimpToPng(jimp, fileName) {
  const buffer = await jimp.getBufferAsync(Jimp.MIME_PNG);
  return new Blob([buffer], { name: fileName, type: "image/png" });
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
