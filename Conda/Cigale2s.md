Here is the complete, cohesive guide to installing the **cigale2s** version from scratch. This guide includes the Git LFS setup, the correct repository branching, Conda configuration, and specific dependency fixes to ensure a smooth, isolated installation that won't conflict with your standard CIGALE setup.

---

### **Step 1: Install and Initialize Git LFS**

Because `cigale2s` uses Git Large File Storage for its data files, you must have Git LFS installed on your system *before* cloning the repository so the heavy dataset files download correctly.

1. Install Git LFS using your system package manager:
```bash
sudo pacman -S git-lfs

```


2. Initialize it for your user account:
```bash
git lfs install

```



---

### **Step 2: Clone the Repository and Switch Branches**

Clone the source code into a brand-new directory named `CIGALE2S` in your home folder, then switch to the specific `cigale2s` branch.

```bash
cd ~
git clone https://gitlab.lam.fr/cigale/cigale.git CIGALE2S
cd CIGALE2S
git checkout cigale2s

```

*(Keep your terminal window inside this `~/CIGALE2S` directory for the rest of the steps).*

---

### **Step 3: Configure Conda Channels**

Ensure Conda prioritizes the `conda-forge` channel as required for this version's dependencies:

```bash
conda config --add channels conda-forge
conda config --set channel_priority strict

```

---

### **Step 4: Create and Activate a New Environment**

Create an isolated environment running Python 3.13. We will name it `cigale2s` to clearly distinguish it from your standard CIGALE environment.

1. Create the environment:
```bash
conda create -n cigale2s python=3.13

```


2. Activate it:
```bash
conda activate cigale2s

```



---

### **Step 5: Install Core Dependencies**

Install `pip` along with the core data science packages required by the `cigale2s` branch:

```bash
conda install pip astropy numpy scipy matplotlib configobj rich h5py

```

---

### **Step 6: Apply the `setuptools` Downgrade Fix**

To bypass a known issue where modern Python environments drop `pkg_resources` (which causes the database builder to throw a `ModuleNotFoundError`), force a compatible version of `setuptools` via pip:

```bash
python -m pip install "setuptools<82"

```

---

### **Step 7: Build the Database**

Build the low-resolution (`'lr'`) backend database for your models. Run this command while inside the `~/CIGALE2S` directory:

```bash
python -c "import database_builder; database_builder.build_base('lr')"

```

*(If you ever need high-resolution SSPs instead, you would change `'lr'` to `'hr'`)*.

---

### **Step 8: Install `cigale2s**`

Perform the editable installation inside your active environment. Make sure to include the trailing dot (`.`):

```bash
python -m pip install -e .

```

---

### **Step 9: Verify the Setup**

Confirm everything is fully linked and functional:

```bash
pcigale --help

```

---

### **Workflow Reminder: Switching Versions**

Because both versions are fully isolated, you can easily switch back and forth depending on what you are working on:

* **To run standard CIGALE:**
```bash
conda activate cigale

```


* **To run cigale2s:**
```bash
conda activate cigale2s

```
