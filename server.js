const express = require('express');
const fs = require('fs');
const path = require('path');
const app = express();

const PORT = process.env.PORT || 3000;

// 📁 Serve the parent folder (the shared content)
const sharedDir = path.resolve(__dirname, '..');

// 📂 Don't expose your project files
const IGNORED_FILES = ['file-share', 'node_modules', 'package.json', 'package-lock.json', '.git'];

function isVisible(name) {
  return !IGNORED_FILES.includes(name);
}

// Use EJS view engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Static route (only for direct static file download)
app.use('/static', express.static(sharedDir));

// Browse files (now at `/`)
app.get('/', (req, res) => {
  const relPath = req.query.path || '';
  const absPath = path.join(sharedDir, relPath);

  fs.readdir(absPath, { withFileTypes: true }, (err, items) => {
    if (err) return res.status(500).send('Unable to read directory');

    const entries = items
      .filter(entry => isVisible(entry.name))
      .map(entry => {
        const fullPath = path.join(relPath, entry.name);
        return {
          name: entry.name,
          isDir: entry.isDirectory(),
          encodedPath: encodeURIComponent(fullPath)
        };
      });

    res.render('file', {
      filename: null,
      encodedPath: null,
      entries
    });
  });
});

// File view (stream/download)
app.get('/file', (req, res) => {
  const relPath = req.query.path;
  if (!relPath) return res.redirect('/');

  const absPath = path.join(sharedDir, relPath);
  const dirPath = path.dirname(relPath);
  const absDir = path.join(sharedDir, dirPath);

  fs.stat(absPath, (err, stats) => {
    if (err || !stats.isFile()) return res.status(404).send('File not found');

    fs.readdir(absDir, { withFileTypes: true }, (err, items) => {
      if (err) return res.status(500).send('Unable to read directory');

      const entries = items
        .filter(entry => isVisible(entry.name))
        .map(entry => {
          const fullPath = path.join(dirPath, entry.name);
          return {
            name: entry.name,
            isDir: entry.isDirectory(),
            encodedPath: encodeURIComponent(fullPath)
          };
        });

      res.render('file', {
        filename: path.basename(relPath),
        encodedPath: encodeURIComponent(relPath),
        entries
      });
    });
  });
});

// Streaming route
app.get('/stream', (req, res) => {
  const filePath = path.join(sharedDir, req.query.path);
  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) return res.status(404).send('File not found');

    const range = req.headers.range;
    if (!range) {
      res.writeHead(200, {
        'Content-Length': stats.size,
        'Content-Type': 'application/octet-stream'
      });
      return fs.createReadStream(filePath).pipe(res);
    }

    const [startStr, endStr] = range.replace(/bytes=/, '').split('-');
    const start = parseInt(startStr, 10);
    const end = endStr ? parseInt(endStr, 10) : stats.size - 1;
    const chunkSize = end - start + 1;

    res.writeHead(206, {
      'Content-Range': `bytes ${start}-${end}/${stats.size}`,
      'Accept-Ranges': 'bytes',
      'Content-Length': chunkSize,
      'Content-Type': 'application/octet-stream'
    });

    fs.createReadStream(filePath, { start, end }).pipe(res);
  });
});

// Download route
app.get('/download', (req, res) => {
  const filePath = path.join(sharedDir, req.query.path);
  res.download(filePath);
});

// Start the server
app.listen(PORT, () => {
  console.log(`✅ Sharing: ${sharedDir}`);
  console.log(`🌐 Open: http://localhost:${PORT}/`);
});
