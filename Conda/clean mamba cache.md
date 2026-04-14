## Guide: Reclaiming Disk Space in Miniforge

Astrophysics packages—especially the full HEASoft suite, Fermitools, and XSPEC data tables—pull down gigabytes of compressed files during installation. Once your environments are successfully built, those leftover installer files sit on your drive and waste valuable space.

Since you are using Miniforge, you can use `mamba` to clean this up incredibly fast. Here is the safest and most effective way to reclaim that space.

### 1. The "Clean Everything" Command (Recommended)

To aggressively clear out all unnecessary installation debris without harming your actual working environments, use the `--all` flag.

Run this in your terminal:

```bash
mamba clean --all

```

*(Note: You will be prompted to confirm y/N for a few different categories of files. You can safely type y for all of them).*

**What exactly does --all remove?**

- **Tarballs (-t):** The compressed `.tar.bz2` or `.conda` files that were downloaded. This is usually where you recover the most space (often several gigabytes).
- **Unused Packages (-p):** Extracted package files that are no longer linked to any of your active environments (such as leftover dependencies from older updates).
- **Index Cache (-i):** The cached lists of available packages from the `conda-forge` and `HEASARC` channels.

**Is it safe?** Yes. This command explicitly checks what is currently being used by your active environments (e.g., `threeML`, `fermi`, `henv`) and leaves those files strictly alone. It only deletes orphaned and cached files.

---

### 2. Targeted Cleaning

If you prefer not to wipe the index cache and only want to delete the heavy downloaded files, you can run these specific commands instead:

**Remove only downloaded archives:**

```bash
mamba clean --tarballs

```

**Remove only unused extracted packages:**

```bash
mamba clean --packages

```

---

### 3. Tracking Down Massive Environments

If you run the clean command and still feel like Conda is taking up too much room, you can check exactly how much space each of your individual environments is using.

Run this standard Linux command to check the size of your Miniforge folders:

```bash
du -sh ~/miniforge3/envs/*

```

This will print out a list of your environments and their sizes in gigabytes or megabytes, making it easy to spot if an old, unused environment is hoarding space.

> **Pro-Tip:** Running `mamba clean --all` every few months—or right after installing a massive suite like HEASoft—is a great habit to keep your CachyOS system lean and optimized.
>
>
