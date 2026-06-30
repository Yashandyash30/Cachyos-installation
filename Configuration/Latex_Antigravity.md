# Complete LaTeX Setup Guide (CachyOS + Niri & Antigravity IDE)

This guide documents the complete LaTeX environment we have set up on your system. It covers everything from the base Arch Linux (CachyOS) system packages to the specific extensions and configurations inside the Antigravity IDE.

## 1. System-Level Installation (CachyOS / Arch Linux)

Since CachyOS is based on Arch Linux, the base LaTeX distribution is provided by the `texlive` packages.

Open your terminal and install the required base packages:

```bash
# Install the comprehensive TeX Live distribution (this is large but ensures you have all packages)
sudo pacman -S texlive-meta

# Alternatively, if you want a minimal installation and add packages as needed:
# sudo pacman -S texlive-basic texlive-latex texlive-latexrecommended
```

**Additional recommended system tools for LaTeX:**
```bash
# For bibliography management and formatting:
sudo pacman -S biber
```

## 2. Antigravity IDE Extensions

Within the Antigravity IDE (which is fully VS Code compatible), we rely on two primary extensions to power the LaTeX workflow:

1. **LaTeX Workshop** (`James-Yu.latex-workshop`)
   - **Purpose:** The core extension that provides building, previewing, and SyncTeX (jumping between code and PDF).
2. **LTeX+** (`ltex-plus.ltex-plus`)
   - **Purpose:** The "gold standard" grammar and spell checker. It intelligently ignores LaTeX commands, math blocks (`$ $`), and environments, so you don't get false positive spelling errors on your equations.

*(You can find and install these in the IDE's Extensions view (`Ctrl+Shift+X`).)*

## 3. IDE Configuration (JSON Files)

We customized the IDE to automatically build on save, configure PDF SyncTeX, and set up a custom dictionary for astrophysics jargon.

### A. Settings (`settings.json`)

To access this, you can open the Command Palette (`Ctrl+Shift+P`), type `Open Settings (JSON)`, and ensure the following LaTeX-related settings are present:

```json
{
    // Automatically build the LaTeX document when you save the file
    "latex-workshop.latex.autoBuild.run": "onSave",

    // Set the built-in PDF viewer to open in a tab inside the editor
    "latex-workshop.view.pdf.viewer": "tab",

    // Configure the PDF formatter (if you are using tex-fmt)
    "latex-workshop.formatting.latex": "tex-fmt",

    // Reverse SyncTeX (PDF -> Code): Double-click anywhere in the PDF preview 
    // to instantly jump to the corresponding line in the .tex code
    "latex-workshop.view.pdf.internal.synctex.keybinding": "double-click",

    // --- LTeX+ Configuration ---
    "ltex.language": "en-US",
    
    // Add custom jargon to the dictionary so LTeX+ stops flagging them as typos
    "ltex.dictionary": {
        "en-US": [
            "MCMC",
            "Piecewise",
            "SyncTeX"
        ]
    }
}
```
*(Your full configuration file is located at [`settings.json`](file:///home/void/.config/Antigravity%20IDE/User/settings.json))*

### B. Keybindings (`keybindings.json`)

We also set up **Forward SyncTeX** (Code -> PDF) so you can quickly jump from your LaTeX code to the exact spot in the rendered PDF. Because the IDE doesn't support binding mouse clicks in `keybindings.json`, we mapped it to a clean keyboard shortcut: `Ctrl + J`.

To access this, open the Command Palette (`Ctrl+Shift+P`), type `Open Keyboard Shortcuts (JSON)`, and add:

```json
[
    {
        "key": "ctrl+j",
        "command": "latex-workshop.synctex",
        "when": "editorTextFocus && editorLangId == 'latex'"
    }
]
```
*(Your full configuration file is located at [`keybindings.json`](file:///home/void/.config/Antigravity%20IDE/User/keybindings.json))*

## 4. Workflow Summary (How to use it)

With everything set up, your workflow in Niri using Antigravity IDE looks like this:

> [!TIP]
> **The Workflow**
> 1. Open your `.tex` file and start typing.
> 2. **Building:** Press `Ctrl + S` to save. LaTeX Workshop will automatically compile the PDF in the background.
> 3. **Forward SyncTeX (Code to PDF):** While your cursor is on a line of code, press **`Ctrl + J`**. The PDF viewer tab will automatically scroll to and highlight the corresponding rendered text.
> 4. **Reverse SyncTeX (PDF to Code):** **Double-click** any text in the PDF viewer tab. The editor will instantly jump to the corresponding line in your `.tex` file.
> 5. **Grammar Checking:** As you type, LTeX+ will analyze your plain text (ignoring your math and macros) and highlight any typos or grammar issues with a squiggly line. Use `Ctrl + .` (Quick Fix) to correct them or add new words to your dictionary.
