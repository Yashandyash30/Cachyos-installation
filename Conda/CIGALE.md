Installation guide for CYGALE

### **Step 1: Download and Extract CIGALE**

If you haven't already, download the source code `.zip` archive from the official CIGALE GitLab repository:
**[https://gitlab.lam.fr/cigale/cigale](https://gitlab.lam.fr/cigale/cigale)**

Option A (Clone via Git): In your terminal, run:

```bash
git clone https://gitlab.lam.fr/cigale/cigale.git
```

Option B (Download Archive): Click the "Code" dropdown button shown in the top right of your screenshot and download the .zip or .tar.gz file. Extract this archive to a location on your computer. You will need to keep this extracted folder for the editable installation.

Extract the downloaded archive into your home directory and ensure the folder is renamed to exactly `CIGALE`.

### **Step 2: Navigate to the CIGALE Folder**

Open your terminal and navigate to the directory where you extracted the code. Since it is in your home folder, run:

```bash
cd ~/CIGALE

```

*(Keep your terminal in this folder for the remainder of the installation).*

### **Step 3: Create and Activate the Conda Environment**

It is best practice to install CIGALE in an isolated environment so its dependencies do not interfere with your system packages.

1. Create a new environment named `cigale` using Python 3.12:
```bash
conda create -n cigale python=3.12

```


2. Activate the environment:
```bash
conda activate cigale

```


*(Note: You must run `conda activate cigale` at the start of any new terminal session before using CIGALE).*

### **Step 4: Install Dependencies (Including `pip`)**

Minimal conda installations (like Miniforge/Miniconda) do not always include `pip` by default. You must install it alongside CIGALE's other required data science packages to prevent the "No module named pip" error.

Run the following command to install `pip` and all necessary dependencies at once:

```bash
conda install pip astropy numpy scipy matplotlib configobj setuptools rich

```

### **Step 5: Build the CIGALE Database**

With the dependencies installed, you need to build the backend database CIGALE uses for its models. Run this command while still inside the `~/CIGALE` directory:

```bash
python setup.py build

```

*(This will output a long list of files being copied into a build folder).*

### **Step 6: Install CIGALE**

Finally, install CIGALE in "editable" mode. This links the software directly to your `~/CIGALE` folder so you can easily pull updates later. Make sure to include the dot (`.`) at the end of the command:

```bash
python -m pip install -e .

```

### **Step 7: Verify the Installation**

To confirm that CIGALE is installed and the commands are properly linked to your `$PATH`, test it by running:

```bash
pcigale --help

```

If this displays the CIGALE help menu, your setup is fully complete and ready for your research.

Try running pcigale, pcigale-filters, or pcigale-plots in your terminal to confirm they are recognized. If your system doesn't recognize the commands, double-check that the installation path is included in your system's $PATH variable.
