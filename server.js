const express = require("express");
const fs = require("fs");
const path = require("path");
const os = require("os");
const { execFile } = require("child_process");
const bodyParser = require("body-parser");

const app = express();

const parentDir = "..";
const directory = process.argv[2] || parentDir;
const PORT = process.env.PORT || 5000;
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

// ---------------- Helper Functions ---------------- //

function getDefaultRootPath() {
  if (process.platform === "win32") {
    return "C:\\";
  } else {
    return "/";
  }
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

function getFolderFromDialog(scriptPath = "utils/select-folder.js") {
  const absPath = path.join(__dirname, scriptPath);
  return new Promise((resolve, reject) => {
    execFile("node", [absPath], { timeout: 30000 }, (error, stdout, stderr) => {
      if (error) {
        console.error("❌ Folder picker error:", error.message || stderr);
        return reject(new Error("Folder picker failed or cancelled."));
      }

      const selectedPath = stdout.trim();
      if (!selectedPath) return reject(new Error("No folder selected."));
      resolve(selectedPath);
    });
  });
}

const IGNORED_FILES = new Set([
  "file-share",
  "node_modules",
  "package.json",
  "package-lock.json",
  ".git",
  ".env",
]);

function isVisible(name) {
  return !IGNORED_FILES.has(name);
}

async function getDirectoryContents(absPath, relPath = "") {
  const items = await fs.promises.readdir(absPath, { withFileTypes: true });
  return items
    .filter((entry) => absPath === "/" || isVisible(entry.name))
    .map((entry) => ({
      name: entry.name,
      isDir: entry.isDirectory(),
      encodedPath: encodeURIComponent(path.join(relPath, entry.name)),
    }));
}

// ---------------- Routes ---------------- //

app.get("/", async (req, res) => {
  // res.render("home");
});

app.get("/home", (req, res) => {
  const url = `http://${localIP}:${PORT}`;
  res.render("home");
});

app.get("/browse", async (req, res) => {
  let rawPath = null;
  if(req.query?.path === "/"){
    rawPath = getDefaultRootPath();
  }else {
    rawPath = decodeURIComponent(req.query.path || "/");
  }

  try {
    if (!fs.existsSync(rawPath)) {
      return res.status(404).render("error", { message: "Path not found" });
    }

    const entries = await getDirectoryContents(rawPath);
    const breadcrumbs = rawPath
      .split("/")
      .filter(Boolean)
      .map((segment, index, array) => {
        const fullPath = "/" + array.slice(0, index + 1).join("/");
        return { name: segment || "/", path: fullPath };
      });

    res.render("browse", {
      currentPath: rawPath,
      entries,
      breadcrumbs,
      path,
    });
  } catch (err) {
    console.error("Browse error:", err);
    res.status(500).render("error", { message: "Failed to read directory" });
  }
});

app.get("/api/select-folder", async (req, res) => {
  try {
    const selectedPath = await getFolderFromDialog();

    if (
      !fs.existsSync(selectedPath) ||
      !fs.lstatSync(selectedPath).isDirectory()
    ) {
      return res
        .status(400)
        .json({ success: false, error: "Invalid directory selected." });
    }

    global.sharedDir = selectedPath;
    res.json({ success: true, path: selectedPath });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// Important: Ensure proper response type to prevent parsing HTML as JSON
app.post("/pick-folder", async (req, res) => {
  const folderPath = req.body.path?.trim();
  console.log("🔄 Requested new share folder:", folderPath);

  if (
    !folderPath ||
    !fs.existsSync(folderPath) ||
    !fs.lstatSync(folderPath).isDirectory()
  ) {
    if (req.headers.accept?.includes("application/json")) {
      return res.status(400).json({ success: false, error: "Invalid folder" });
    } else {
      return res.status(400).send("Invalid folder");
    }
  }

  sharedDir = folderPath;
  global.sharedDir = folderPath;
  console.log(`📁 New shared folder set to: ${sharedDir}`);

  if (req.headers.accept?.includes("application/json")) {
    return res.json({ success: true });
  } else {
    return res.redirect("/files");
  }
});

app.get("/files", async (req, res) => {
  const relPath = "";
  const baseDir = global.sharedDir || sharedDir;
  const absPath = path.join(baseDir, relPath);

  if (!absPath.startsWith(baseDir)) {
    return res.status(403).render("error", { message: "Access denied" });
  }

  const entries = await getDirectoryContents(absPath, relPath);
  res.render("index", { path: relPath, entries, localIP, port: PORT });
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
  const filePath = path.join(global.sharedDir || sharedDir, req.query.path);
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
  const filePath = path.join(global.sharedDir || sharedDir, req.query.path);
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

// ---------------- Error Handling ---------------- //

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

// ---------------- Start Server ---------------- //

app.listen(PORT, () => {
  console.log(`✅ Sharing: ${sharedDir}`);
  console.log(`🌐 Open: http://localhost:${PORT}/`);
});
