Here’s your updated and cleaned-up `README.md`, aligned with the **current version** of your project where users only need to run `run.bat` or `run.sh`:

---

````markdown
# File Sharing Application

A simple cross-platform file sharing application built using Node.js, with optional GUI folder selection powered by Python.

## Features

- Share any folder over your local (home) network.
- Access shared folders through a browser-based interface.
- Works on both **Windows** and **Linux** systems.
- No installation needed — just run and share!

## Getting Started

You can either **clone the repository** or **download the ZIP** of this project.

### 1. Clone the Repository

```bash
git clone <repository_url>
```


### 2. Set current directory
```bash
cd files_sharing_backend
````

Or simply [download the ZIP](https://github.com/ShejulShubham/files_sharing_backend) and extract it.

---

## Usage

After downloading/cloning:

* On **Windows**, double-click or run:

  ```
  run.bat
  ```

* On **Linux**, execute:

  ```bash
  ./run.sh
  ```

You will be prompted to choose an interface mode:

* **CLI** – select folder via terminal.
* **GUI** – choose folder via graphical window.

Once selected, your chosen folder will be shared on your local network, accessible via browser using a URL like:

```
http://<host-ip>:<port>
```

---

## Folder Structure

```bash
/gui         → Python GUI for folder selection
/log         → App log files, gets created after running the app
/scripts     → Mode launchers (start_cli.*, start_gui.*)
/src
  ├── /utils → Helpers like IP detection
  └── /views → Express route handlers
run.sh       → Linux entry point
run.bat      → Windows entry point
```

---

## Contributing

Feel free to open issues or pull requests. Bug fixes, features, or documentation improvements are welcome.

---

## License

This project is licensed under the MIT License.