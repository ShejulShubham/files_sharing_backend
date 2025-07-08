# 📁 File Sharing Web App

A clean, responsive file sharing and streaming web application built using **Node.js**, **Express**, and **EJS** templating.  
Supports file/folder browsing, media streaming (audio/video/image), text preview, file downloads, and QR sharing.

---

## 🚀 Features

- 📂 Browse directories & subfolders
- 📄 View file details & sizes
- 🎥 Preview images, videos, audio, and text files
- 📥 Download files with a single click
- 📱 Share links via QR code (mobile-friendly)
- 🌙 Light/Dark mode with Bootstrap 5
- 🔐 Secure relative path resolution

---

## 🧩 Prerequisites

| Tool           | Version        |
|----------------|----------------|
| Node.js        | v16+ or v18+   |
| npm            | Installed with Node.js |
| git            | For cloning repo |
| Bash/Zsh       | (for Linux setup script) |

---

## 💻 Setup Instructions

### 🪟 Windows

1. **Install Node.js:**
   - Download and install from [https://nodejs.org](https://nodejs.org)

2. **Clone the project or download ZIP into the folder you want to share:**
   ```bash
   git clone https://github.com/ShejulShubham/files_sharing_backend
   cd files-sharing-app
   ```

3. **Install dependencies:**

   ```bash
   npm install
   ```

4. **Run the app:**

   double click on file `start.bat` it will open a command line with hosting URL

5. **Open your browser:**

   * [http://localhost:5000](http://localhost:5000)

---

### 🐧 Linux / Ubuntu / WSL

1. **Install Node.js using NVM:**

   ```bash
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
   source ~/.bashrc
   nvm install 18
   nvm use 18
   ```

2. **Clone the project or download ZIP into the folder you want to share:**

   ```bash
   git clone https://github.com/ShejulShubham/files_sharing_backend
   cd files-sharing-app
   ```

3. **Install dependencies:**

   ```bash
   npm install
   ```

4. **Run with auto-setup script:**

   > Includes dynamic IP display and browser launch

   ```bash
   chmod +x ./start.sh
   ./start.sh
   ```

---

## ⚙️ Customize

* **Change shared folder:**
  Modify `sharedDir` in `server.js` to point to a different directory.

* **Change port:**
  Update `PORT=5000` in script.

---

## 🧑‍💻 Author

**Shejul Shubham**
[LinkedIn](https://www.linkedin.com/in/shejul-shubham) | [GitHub](https://github.com/shejulshubham)
