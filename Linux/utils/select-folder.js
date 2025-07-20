// utils/select-folder.js
const nfd = require("node-file-dialog");

(async () => {
  try {
    const path = await nfd({
      type: "directory",
      multiple: false,
    });

    if (!path || path.length === 0) {
      throw new Error("No folder selected.");
    }

    // Print first (and only) selected path
    console.log(path[0]);
  } catch (err) {
    console.error("❌ Folder selection cancelled or failed.");
    process.exit(1);
  }
})();
