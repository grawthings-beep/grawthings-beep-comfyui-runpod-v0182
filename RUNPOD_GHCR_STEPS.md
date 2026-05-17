# GHCR + RunPod Steps

## 1. Create a GitHub repository

Create a new repository on GitHub.

- Repository name: `comfyui-runpod`
- Visibility: public or private is OK
- Do not add README or .gitignore from GitHub

## 2. Push this directory to GitHub

Run these commands in PowerShell:

```powershell
cd C:\Users\grawt\Documents\Codex\2026-05-17\runpod-comunity-cloud-lora-comfyui-latest

git init
git branch -M main
git add .
git commit -m "Add RunPod ComfyUI image"
git remote add origin https://github.com/YOUR_GITHUB_USER/comfyui-runpod.git
git push -u origin main
```

Replace `YOUR_GITHUB_USER` with your GitHub user or organization name.

## 3. Build the image with GitHub Actions

Open the repository on GitHub:

1. Open `Actions`.
2. Select `Build GHCR image`.
3. Click `Run workflow` if it did not run automatically.
4. Wait for the workflow to finish.

The workflow publishes:

```text
ghcr.io/YOUR_GITHUB_USER/comfyui-runpod:cuda12.8
```

## 4. Make the GHCR package public

After the first push:

1. Open your GitHub profile.
2. Open `Packages`.
3. Open `comfyui-runpod`.
4. Open `Package settings`.
5. Use `Change visibility` and select `Public`.

Public packages can be pulled by RunPod without registry credentials.

## 5. Create a RunPod template

In RunPod Console, open `Templates` and create a new template.

- Container Image: `ghcr.io/YOUR_GITHUB_USER/comfyui-runpod:cuda12.8`
- Container Disk: `40 GB` or more
- Volume Disk: larger than the models downloaded during the Pod lease
- HTTP Port: `8188`
- Start Command: leave empty

Leave Network Volume empty when you want maximum Community Cloud GPU availability.

## 6. Add environment variables

Minimum:

```text
PORT=8188
LISTEN=0.0.0.0
RUN_DEP_CHECK=1
```

Use a manifest URL:

```text
MODEL_MANIFEST_URL=https://example.com/models.json
```

Or inline JSON:

```text
MODEL_MANIFEST_JSON={"models":[{"name":"base","enabled":true,"url":"https://example.com/model.safetensors","path":"models/checkpoints/model.safetensors"}]}
```

Optional tokens:

```text
HF_TOKEN=...
CIVITAI_TOKEN=...
```

## 7. Deploy on Community Cloud

Deploy a Pod using the template. In the logs, confirm:

- Docker image pull completed
- Model downloads completed
- `cuda_available: True`
- GPU name is printed
- ComfyUI starts on port `8188`

Open the RunPod HTTP service for port `8188`.
