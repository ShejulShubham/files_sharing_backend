const express = require("express");
const path = require("path");
const os = require("os");
const bodyParser = require("body-parser");
const fs = require("fs");
const path = require("path");
const dotenv = require("dotenv");

// Load .env from parent directory
dotenv.config({ path: path.resolve(__dirname, "../.env") });

const app = express();

const parentDir = "..";
const directory = process.argv[2] || parentDir;
const argPort = process.argv[2];
const envPort = process.env.PORT;
const PORT = argPort || envPort || 5000;
let sharedDir = path.resolve(__dirname, directory);
const localIP = getLocalIP();

// Middleware
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.set("view engine", "ejs");
app.set("views", path.join(__dirname, "views"));

app.use("/static", (req, res, next) => {
  const staticDir = global.sharedDir || sharedDir;
  express.static(staticDir, {
    dotfiles: "ignore",
    index: false,
  })(req, res, next);
});

function getDefaultRootPath() {
  return process.platform === "win32" ? "C:\\" : "/";
}

function getLocalIP() {
  const interfaces = os.networkInterfaces();
  for (const iface of Object.values(interfaces)) {
    for (const config of iface) {
      if (
        config.family === "IPv4" &&
        !config.internal &&
        !config.address.startsWith("172.")
      ) {
        return config.address;
      }
    }
  }
  return "localhost";
}

function formatFileSize(bytes) {
  if (bytes === 0) return "0 B";
  const k = 1024;
  const sizes = ["B", "KB", "MB", "GB", "TB"];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + " " + sizes[i];
}

function getFileTypeLabel(ext) {
  const types = {
    image: ["jpg", "jpeg", "png", "gif", "webp", "svg", "bmp"],
    video: ["mp4", "webm", "mkv"],
    audio: ["mp3", "wav", "ogg"],
    text: ["txt", "log", "json", "md"],
    pdf: ["pdf"],
    archive: ["zip", "rar", "tar", "gz"],
    code: ["js", "html", "css", "java", "py", "cpp", "c", "ts", "php"],
  };

  for (const [label, extensions] of Object.entries(types)) {
    if (extensions.includes(ext)) {
      return label.charAt(0).toUpperCase() + label.slice(1) + " File";
    }
  }

  return "Unknown File Type";
}

const IGNORED_FILES = new Set([
  "file-share",
  "node_modules",
  "package.json",
  "package-lock.json",
  ".git",
  ".env",
]);

function isSystemFile(fileName) {
  const isWindows = process.platform === "win32";

  const windowsSystemFiles = new Set([
    "$Recycle.Bin",
    "System Volume Information",
    "pagefile.sys",
    "swapfile.sys",
    "hiberfil.sys",
    "Program Files",
    "Program Files (x86)",
    "Windows",
    "$WinREAgent",
    "PerfLogs",
    "Recovery",
    "Documents and Settings",
    "ProgramData",
    "System32",
  ]);

  const linuxSystemFiles = new Set([
    "boot",
    "dev",
    "etc",
    "lib",
    "lib64",
    "proc",
    "run",
    "sbin",
    "sys",
    "usr",
    "var",
    "tmp",
    "snap",
    "lost+found",
    "root",
    "srv",
    "mnt",
    "media",
  ]);

  if (isWindows) {
    return windowsSystemFiles.has(fileName);
  }

  return linuxSystemFiles.has(fileName);
}

function isHiddenFile(fileName) {
  return fileName.startsWith(".");
}

function isVisible(name) {
  return !IGNORED_FILES.has(name) && !isSystemFile(name) && !isHiddenFile(name);
}

async function getDirectoryContents(absPath, relPath = "") {
  const items = await fs.promises.readdir(absPath, { withFileTypes: true });
  return items
    .filter((entry) => isVisible(entry.name))
    .map((entry) => ({
      name: entry.name,
      isDir: entry.isDirectory(),
      encodedPath: encodeURIComponent(path.join(relPath, entry.name)),
    }));
}

// Routes
app.get("/", (req, res) => res.redirect("/files"));

app.get("/ping", (req, res) => res.status(200).send("OK"));

app.post("/pick-folder", async (req, res) => {
  const folderPath = req.body.path?.trim();
  console.log("🔄 Requested new share folder:", folderPath);

  if (
    !folderPath ||
    !fs.existsSync(folderPath) ||
    !fs.lstatSync(folderPath).isDirectory()
  ) {
    const errorMsg = "Invalid folder";
    return req.headers.accept?.includes("application/json")
      ? res.status(400).json({ success: false, error: errorMsg })
      : res.status(400).send(errorMsg);
  }

  sharedDir = path.resolve(folderPath);
  global.sharedDir = path.resolve(folderPath);
  console.log(`📁 New shared folder set to: ${sharedDir}`);

  return req.headers.accept?.includes("application/json")
    ? res.json({ success: true })
    : res.redirect("/files");
});

app.get("/files", async (req, res) => {
  const relPath = decodeURIComponent(req.query.path || "");
  const baseDir = global.sharedDir || sharedDir;
  const absPath = path.join(baseDir, relPath);

  if (!absPath.startsWith(baseDir)) {
    return res.status(403).render("error", { message: "Access denied" });
  }

  try {
    const entries = await getDirectoryContents(absPath, relPath);
    res.render("index", { path: relPath, entries, localIP, port: PORT });
  } catch (err) {
    console.error("Error getting directory contents for /files:", err);
    res
      .status(500)
      .render("error", { message: "Failed to read directory contents." });
  }
});

app.get("/file", async (req, res) => {
  try {
    const relPath = decodeURIComponent(req.query.path || "");
    if (!relPath) return res.redirect("/");

    const baseDir = global.sharedDir || sharedDir;
    const absPath = path.join(baseDir, relPath);
    const dirPath = path.dirname(relPath);
    const absDir = path.join(baseDir, dirPath);

    const stats = await fs.promises.stat(absPath);
    if (!stats.isFile())
      return res.status(404).render("error", { message: "File not found" });

    const entries = await getDirectoryContents(absDir, dirPath);
    const filename = path.basename(relPath);
    const ext = filename.split(".").pop().toLowerCase();
    const fileSize = stats.size;
    const fileSizeFormatted = formatFileSize(fileSize);
    const fileTypeLabel = getFileTypeLabel(ext);
    let content = "";

    const textTypes = ["txt", "log", "json", "md"];
    if (textTypes.includes(ext)) {
      content = await fs.promises.readFile(absPath, "utf-8");
    }

    res.render("file", {
      path: relPath,
      filename,
      encodedPath: encodeURIComponent(relPath),
      entries,
      fileContent: content,
      fileSize,
      fileSizeFormatted,
      fileTypeLabel,
      localIP,
      port: PORT,
    });
  } catch (err) {
    console.error("Error viewing file:", err);
    res.status(500).render("error", { message: "Error loading file" });
  }
});

app.get("/stream", (req, res) => {
  const requestedPath = decodeURIComponent(req.query.path || "");
  const baseDir = global.sharedDir || sharedDir;
  const filePath = path.join(baseDir, requestedPath);

  if (!filePath.startsWith(baseDir)) {
    return res.status(403).send("Access denied");
  }

  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) return res.status(404).send("File not found");

    const range = req.headers.range;
    if (!range) {
      res.writeHead(200, {
        "Content-Length": stats.size,
        "Content-Type": "application/octet-stream",
      });
      return fs.createReadStream(filePath).pipe(res);
    }

    const [startStr, endStr] = range.replace(/bytes=/, "").split("-");
    const start = parseInt(startStr, 10);
    const end = endStr ? parseInt(endStr, 10) : stats.size - 1;

    res.writeHead(206, {
      "Content-Range": `bytes ${start}-${end}/${stats.size}`,
      "Accept-Ranges": "bytes",
      "Content-Length": end - start + 1,
      "Content-Type": "application/octet-stream",
    });

    fs.createReadStream(filePath, { start, end }).pipe(res);
  });
});

app.get("/download", (req, res) => {
  const requestedPath = decodeURIComponent(req.query.path || "");
  const baseDir = global.sharedDir || sharedDir;
  const filePath = path.join(baseDir, requestedPath);

  if (!filePath.startsWith(baseDir)) {
    return res.status(403).send("Access denied");
  }

  res.download(filePath);
});

app.get("/exit", (req, res) => {
  res.send("🛑 Server stopping...");
  setTimeout(() => {
    console.log("Server stopped by user.");
    process.exit(0);
  }, 500);
});

app.post("/shutdown", (req, res) => {
  res.send("Shutting down...");
  console.log("🛑 Shutdown requested from browser.");
  setTimeout(() => {
    process.exit(0);
  }, 1000);
});

app.use((err, req, res, next) => {
  console.error("Server error:", err);
  if (req.headers.accept?.includes("application/json")) {
    res.status(500).json({ success: false, error: err.message });
  } else {
    res
      .status(500)
      .render("error", { message: err.message || "Internal server error" });
  }
});

app.use((req, res) => {
  if (req.headers.accept?.includes("application/json")) {
    res.status(404).json({ success: false, error: "Not found" });
  } else {
    res.status(404).render("error", { message: "Page not found" });
  }
});

app.listen(PORT, () => {
  console.log(`✅ Sharing: ${sharedDir}`);
  console.log(`🌐 Open: http://${localIP}:${PORT}/`);
});