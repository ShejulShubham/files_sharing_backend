const { app, BrowserWindow, dialog, ipcMain, shell } = require("electron");
const { exec } = require("child_process");
const os = require("os");
const path = require("path");

let mainWindow;

// 🌐 Get the current local IP address
function getLocalIP() {
  const nets = os.networkInterfaces();
  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      if (net.family === "IPv4" && !net.internal) {
        return net.address;
      }
    }
  }
  return "localhost";
}

// 🧠 Helper to detect if we're in dev mode
function isDev() {
  return !app.isPackaged;
}

// 📁 Get correct path to views folder
function getViewsDir() {
  return isDev()
    ? path.join(__dirname, "views") // dev: ./views
    : path.join(process.resourcesPath, "views"); // prod: /resources/views
}

// 📄 Get correct path to server.js
function getServerScript() {
  return isDev()
    ? path.join(__dirname, "server.js") // dev: ./server.js
    : path.join(process.resourcesPath, "server.js"); // prod: /resources/server.js
}

// 🪟 Create Electron window and load welcome page
function createWindow() {
  mainWindow = new BrowserWindow({
    width: 600,
    height: 400,
    resizable: false,
    title: "📁 File Sharing App",
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
    },
  });

  const viewsDir = getViewsDir();
  mainWindow.loadFile(path.join(viewsDir, "welcome.html"));
}

// 📁 Handle folder selection and start server
ipcMain.on("open-folder-dialog", async () => {
  const result = await dialog.showOpenDialog(mainWindow, {
    properties: ["openDirectory"],
  });

  if (result.canceled) return;

  const sharedPath = result.filePaths[0];
  const port = 5000;
  const url = `http://localhost:${port}`;
  const networkUrl = `http://${getLocalIP()}:${port}`;
  const serverScript = getServerScript();

  const command = `PORT=${port} node "${serverScript}" "${sharedPath}"`;

  exec(command, (err, stdout, stderr) => {
    if (err) {
      console.error("❌ Server Error:", stderr);
      mainWindow.webContents.send("log", "❌ Failed to start the server.");
    }
  });

  const viewsDir = getViewsDir();
  mainWindow.loadFile(path.join(viewsDir, "status.html")).then(() => {
    mainWindow.webContents.send("app-data", { sharedPath, url, networkUrl });
  });
});

// 🌐 Open the shared link in browser
ipcMain.on("open-in-browser", (_, url) => {
  shell.openExternal(url);
});

app.whenReady().then(createWindow);

app.disableHardwareAcceleration();
