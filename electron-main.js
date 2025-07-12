const { app, BrowserWindow, dialog, ipcMain, shell } = require("electron");
const { exec } = require("child_process");
const os = require("os");
const path = require("path");

let mainWindow;

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

  mainWindow.loadFile(path.join(__dirname, "views", "welcome.html"));
}

ipcMain.on("open-folder-dialog", async () => {
  const result = await dialog.showOpenDialog(mainWindow, {
    properties: ["openDirectory"],
  });

  if (result.canceled) return;

  const sharedPath = result.filePaths[0];
  const port = 5000;
  const url = `http://localhost:${port}`;
  const networkUrl = `http://${getLocalIP()}:${port}`;

  // ✅ Path to server.js (works for both dev and packaged app)
  const serverScript = path.join(
    process.resourcesPath,
    process.platform === "win32" ? "server.js" : "./server.js"
  );

  const command = `PORT=${port} node "${path.join(
    __dirname,
    "server.js"
  )}" "${sharedPath}"`;

  exec(command, (err, stdout, stderr) => {
    if (err) {
      console.error("❌ Server Error:", stderr);
      mainWindow.webContents.send("log", "❌ Failed to start the server.");
    }
  });

  // Load the status UI and send folder data
  mainWindow.loadFile(path.join(__dirname, "views", "status.html")).then(() => {
    mainWindow.webContents.send("app-data", { sharedPath, url, networkUrl });
  });
});

ipcMain.on("open-in-browser", (_, url) => {
  shell.openExternal(url);
});

app.whenReady().then(createWindow);

app.disableHardwareAcceleration();
