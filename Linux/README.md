# File Sharing Application

This is a simple file sharing application built with Node.js and Express.

## Features

- Share files and directories over your local network.
- Browse shared content through a web interface.
- Download individual files.
- Stream video and audio files.

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

To start the application in CLI mode:

```bash
./start_cli.sh
```

This will prompt you to select a directory to share. If no directory is provided, it will share the parent directory of the application.

### GUI Mode (Windows)

To start the application in GUI mode on Windows:

```bash
start_gui.bat
```

This will open a browser window with the application.

### GUI Mode (Linux)

To start the application in GUI mode on Linux:

```bash
./start_gui.sh
```

This will open a browser window with the application.

## Contributing

Feel free to contribute to this project by opening issues or submitting pull requests.

## License

This project is licensed under the MIT License.