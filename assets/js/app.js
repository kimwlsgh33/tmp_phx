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
import ThemeToggle from "./hooks/theme_toggle";
import DocsNavigation from "./hooks/docs_navigation";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let Hooks = {
  ThemeToggle,
  DocsNavigation,
};
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

// Add debug logging for socket connection
console.log("[LiveView] Initializing LiveSocket...");

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
console.log("[LiveView] Attempting to connect LiveSocket...");
liveSocket.connect();

// Add event listeners for socket connection status
liveSocket.socket.onOpen(() => console.log("[LiveView] Socket CONNECTED"));
liveSocket.socket.onClose(() => console.log("[LiveView] Socket DISCONNECTED"));
liveSocket.socket.onError((error) => console.error("[LiveView] Socket ERROR:", error));
// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

// Enable debug mode to see detailed LiveView messages in console
liveSocket.enableDebug();
console.log("[LiveView] Debug mode enabled. Check browser console for detailed messages.");

// spinner
document.addEventListener("DOMContentLoaded", () => {
  const spinner = document.getElementById("global-spinner");
  const path = spinner.querySelector("path");
  const content = document.getElementById("page-content");
  const pathLength = path.getTotalLength();

  path.style.setProperty("--path-length", pathLength);
  path.style.strokeDasharray = pathLength;
  path.style.strokeDashoffset = pathLength;

  // 페이지 로딩 시작 시
  window.addEventListener("phx:page-loading-start", () => {
    spinner.style.display = "block";
    content.style.display = "none";
  });

  // 페이지 로딩 완료 시
  window.addEventListener("phx:page-loading-stop", () => {
    spinner.style.display = "none";
    content.style.display = "block";
    content.classList.remove("hidden"); // 부드러운 전환을 위해
  });
  
  console.log("[LiveView] Page initialization complete");
  
  // Debug helper functions for use in browser console
  window.checkLiveSocket = () => {
    console.log("[LiveView] Connection status:", liveSocket.isConnected() ? "CONNECTED" : "DISCONNECTED");
    console.log("[LiveView] Socket object:", liveSocket.socket);
    return liveSocket.isConnected();
  };
});
