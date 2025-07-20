Your README is quite clear and well-structured! Just a few **grammatical and stylistic improvements** are suggested for better readability and professionalism.

Here’s the **revised README** with corrections and improvements:

---

# File Sharing Application

This is a simple file sharing application built with Node.js and Express.

## Features

* Share files and directories over your local network.
* Browse shared content through a web interface.
* Download individual files.
* Stream video and audio files.

## Installation

1. Clone the repository:

   ```bash
   git clone <repository_url>
   cd files_sharing_backend
   ```

2. Install dependencies:

   ```bash
   npm install
   ```

## Usage

### CLI Mode

To start the application in **CLI mode**:

```bash
./start_cli.sh
```

You will be prompted to select a directory to share. If no directory is provided, the parent directory of the application will be shared by default.

### GUI Mode (Windows)

To start the application in **GUI mode on Windows**:

```bash
start_gui.bat
```

This will launch the application in your default browser.

### GUI Mode (Linux)

To start the application in **GUI mode on Linux**:

```bash
./start_gui.sh
```

This will launch the application in your default browser.

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests to improve the project.

## License

This project is licensed under the **MIT License**.