const express = require('express');
const fs = require('fs');
const path = require('path');
const app = express();
const PORT = 3000;

const sharedDir = path.join(__dirname, 'public');
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use('/static', express.static(sharedDir)); // direct file access

// Homepage: list files
app.get('/files', (req, res) => {
  const relPath = req.query.path || '';
  const absPath = path.join(sharedDir, relPath);

  fs.readdir(absPath, { withFileTypes: true }, (err, items) => {
    if (err) return res.status(500).send('Error reading directory');

    const entries = items.map(entry => {
      const name = entry.name;
      const fullPath = path.join(relPath, name);
      return {
        name,
        isDir: entry.isDirectory(),
        encodedPath: encodeURIComponent(fullPath)
      };
    });

    res.render('index', {
      path: relPath,
      entries
    });
  });
});

// File UI: stream or download
app.get('/file', (req, res) => {
  const relPath = req.query.path;
  const absPath = path.join(sharedDir, relPath);
  const dirPath = path.dirname(relPath); // get folder containing the file
  const absDir = path.join(sharedDir, dirPath);

  fs.stat(absPath, (err, stats) => {
    if (err || !stats.isFile()) return res.status(404).send('File not found');

    fs.readdir(absDir, { withFileTypes: true }, (err, items) => {
      if (err) return res.status(500).send('Error reading directory');

      const entries = items.map(entry => {
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


// Stream route
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

app.listen(PORT, () => {
  console.log(`✅ Browse: http://localhost:${PORT}/files`);
});
