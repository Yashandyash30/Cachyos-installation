To prevent editor automatically formatting the json file into expands objects into multiple lines when you saved it (or pressed a format shortcut). Uou can disable **Format On Save** specifically for JSON files:

1. Open your Settings by pressing `Ctrl+,` (or `Cmd+,` on Mac).
2. Click on the **Open Settings (JSON)** icon in the top right corner (it looks like a piece of paper with a little arrow).
3. Add the following to your `settings.json`:

```json
  "[jsonc]": {
      "editor.formatOnSave": false
  },
  "[json]": {
      "editor.formatOnSave": false
  }
```

This will prevent the editor from auto-rearranging your `config.jsonc` whenever you hit save!
