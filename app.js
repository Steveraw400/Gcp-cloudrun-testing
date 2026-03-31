const http = require("http");
const fs = require("fs");
const path = require("path");

const PORT = process.env.PORT || 8080;

const server = http.createServer((req, res) => {
  
  // Serve the form
  if (req.method === "GET" && req.url === "/") {
    const filePath = path.join(__dirname, "index.html");
    fs.readFile(filePath, (err, data) => {
      if (err) {
        res.writeHead(500);
        res.end("Error loading form");
        return;
      }
      res.writeHead(200, { "Content-Type": "text/html" });
      res.end(data);
    });

  // Handle form submission
  } else if (req.method === "POST" && req.url === "/") {
    let body = "";
    req.on("data", chunk => body += chunk);
    req.on("end", () => {
      const params = new URLSearchParams(body);
      const name = params.get("name");
      const email = params.get("email");
      console.log(`Form submission - Name: ${name}, Email: ${email}`);
      res.writeHead(200, { "Content-Type": "text/html" });
      res.end(`<h1>Thanks, ${name}! We'll be in touch at ${email} 🚀</h1>`);
    });

  } else {
    res.writeHead(404);
    res.end("Not found");
  }
});

server.listen(PORT, "0.0.0.0", () => {
  console.log("Server running on port " + PORT);
});