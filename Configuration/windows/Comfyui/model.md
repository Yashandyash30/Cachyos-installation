All models have been moved directly into your portable version, and `extra_model_paths.yaml` has been deleted as requested.

---

### 1. What was moved to your Portable ComfyUI:

All files were moved directly into **`C:\Drive_E\Comfyui\comfyui-rocm-091926\models\`** (saving you over 14 GB of redownloading):

| Model File | Destination Folder |
| :--- | :--- |
| **`flux1-dev-Q5_1.gguf`** | `...\models\unet\` |
| **`ae.safetensors`** | `...\models\vae\` |
| **`clip_l.safetensors`** | `...\models\clip\` |
| **`t5xxl_fp8_e4m3fn.safetensors`** | `...\models\clip\` |
| **`qwen_image_2.1_int8_convrot.safetensors`** | `...\models\diffusion_models\` |
| **`qwen3vl_8b_int8_convrot.safetensors`** | `...\models\text_encoders\` |
| **`qwen_image_2.1_vae_bf16.safetensors`** | `...\models\vae\` |
| **Face restore models** (`codeformer`, `GFPGAN`, `GPEN`) | `...\models\facerestore_models\` |

---

### 2. YAML Removed:
* **`extra_model_paths.yaml`** has been **completely deleted**.  
* Your portable ComfyUI now reads exclusively from its own internal `models\` directory.

---

### 3. How to Uninstall ComfyUI Desktop:

Now that your model files have been moved out of it, you can safely uninstall the desktop app:

1. Press `Win` + `I` to open **Settings** $\rightarrow$ **Apps** $\rightarrow$ **Installed apps** (or press `Win` + `R`, type `appwiz.cpl`, and press Enter).
2. Find **Comfy Desktop** in the list.
3. Click the three dots $\rightarrow$ **Uninstall**.
4. *(Optional)* To reclaim any leftover cache space after uninstalling, you can delete the folder:  
   `C:\Users\void\AppData\Local\Comfy-Desktop`