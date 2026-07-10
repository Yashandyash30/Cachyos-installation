### **Installation Guide for `antigravity-nb`**

#### **Step 1: Register Your Environment as a Kernel**

Before installing the MCP server, ensure your desired Conda/Miniforge environment has a Jupyter kernel installed so the AI has an engine to execute the code.

```bash
# 1. Activate your target environment
conda activate your_env_name

# 2. Install the kernel package (if not already installed)
conda install ipykernel

# 3. Register it with Jupyter
python -m ipykernel install --user --name your_env_name --display-name "Python (your_env_name)"

```

#### **Step 2: Install the MCP Server**

Install the tool directly from the GitHub repository using `pip`. Make sure your target environment is still active when you do this.

```bash
pip install git+https://github.com/Ian747-tw/Antigravity-Jupiter-Notebook-MCP.git

```

#### **Step 3: Find the Absolute Executable Path (The Crucial Step)**

To prevent "Status 500" or "Command not found" errors when launching the editor outside of a terminal, find exactly where your system installed the tool.

Run this in your terminal:

```bash
which antigravity-nb

```

*Note the output path carefully. (e.g., `/home/void/miniforge3/bin/antigravity-nb` or `~/.local/bin/antigravity-nb`).*

#### **Step 4: Configure the JSON File**

1. Open your Antigravity configuration file, usually located at: `~/.gemini/antigravity/mcp_config.json`
2. Add the `antigravity-nb` block to the `mcpServers` object, replacing the `"command"` value with the exact path you got from Step 3.

```json
{
"mcpServers": {
"antigravity-nb": {
"command": "/YOUR/EXACT/PATH/FROM/STEP/3/antigravity-nb",
"args": [
"serve-agent",
"--workspace-root",
"${workspaceFolder}"
]
}
}
}

```

*(Make sure to add a comma before `"antigravity-nb"` if you have other servers listed above it!)*

#### **Step 5: Reload and Verify**

1. Open the Command Palette in the editor (`Ctrl` + `Shift` + `P`) and run **`Refresh MCP Servers`** (or just restart the editor).
2. Ask the AI: *"List the tools available from antigravity-nb"*
3. Create a `test.ipynb`, add `print("MCP works!")` to the first cell, and ask the AI to run it.

If it prints the message, your sandboxed AI Jupyter environment is perfectly configured!
