const express = require("express");
const fs = require("fs");
const path = require("path");
const app = express();
const os = require("os");

const PORT = process.env.PORT || 3000;
const sharedDir = path.resolve(__dirname, "..");

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
  "files_sharing_backend",
  "file-share",
  "node_modules",
  "package.json",
  "package-lock.json",
  ".git",
  ".env",
]);

function getLocalIP() {
  const interfaces = os.networkInterfaces();
  for (const iface of Object.values(interfaces)) {
    for (const config of iface) {
      if (
        config.family === "IPv4" &&
        !config.internal &&
        !config.address.startsWith("172.") // skip docker IPs
      ) {
        return config.address;
      }
    }
  }
  return "localhost";
}

const localIP = getLocalIP();

function isVisible(name) {
  return !IGNORED_FILES.has(name);
}

app.set("view engine", "ejs");
app.set("views", path.join(__dirname, "views"));

app.use(
  "/static",
  express.static(sharedDir, { dotfiles: "ignore", index: false })
);

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

app.get("/", async (req, res) => {
  const entries = await getDirectoryContents(sharedDir);
  res.render("index", { path: "", entries, localIP, port: PORT });
});

app.get("/files", async (req, res) => {
  const relPath = req.query.path || "";
  const absPath = path.join(sharedDir, relPath);
  if (!absPath.startsWith(sharedDir))
    return res.status(403).render("error", { message: "Access denied" });

  const entries = await getDirectoryContents(absPath, relPath);
  res.render("index", { path: relPath, entries, localIP, port: PORT });
});

app.get("/file", async (req, res) => {
  try {
    const relPath = decodeURIComponent(req.query.path || "");
    if (!relPath) return res.redirect("/");

    const absPath = path.join(sharedDir, relPath);
    const dirPath = path.dirname(relPath);
    const absDir = path.join(sharedDir, dirPath);

    const stats = await fs.promises.stat(absPath);
    if (!stats.isFile())
      return res.status(404).render("error", { message: "File not found" });

    const fileSize = stats.size;

    const entries = await getDirectoryContents(absDir, dirPath);

    const filename = path.basename(relPath);
    const ext = filename.split(".").pop().toLowerCase();
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
  const filePath = path.join(sharedDir, req.query.path);
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
  const filePath = path.join(sharedDir, req.query.path);
  res.download(filePath);
});

app.use((err, req, res, next) => {
  console.error("Server error:", err);
  res
    .status(500)
    .render("error", { message: err.message || "Internal server error" });
});

app.use((req, res) => {
  res.status(404).render("error", { message: "Page not found" });
});

app.listen(PORT, () => {
  console.log(`✅ Sharing: ${sharedDir}`);
  console.log(`🌐 Open: http://localhost:${PORT}/`);
});
