const http = require("http");
const os = require("os");

const port = process.env.PORT || 8080;

http
  .createServer((req, res) => {
    if (req.url === "/healthz") {
      res.writeHead(200, { "Content-Type": "text/plain" });
      return res.end("ok");
    }
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(
      JSON.stringify({
        app: "hello-node",
        message: "Hello from Node.js on GKE",
        path: req.url,
        pod: os.hostname(),
        version: process.env.APP_VERSION || "dev",
      })
    );
  })
  .listen(port, () => console.log(`hello-node listening on ${port}`));
