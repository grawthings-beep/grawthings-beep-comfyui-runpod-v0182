# syntax=docker/dockerfile:1.7

# Default is a broad RunPod/PyTorch CUDA 12.8 base that works well for modern
# NVIDIA GPUs. For Blackwell-first fleets, keep CUDA 12.8+. For older-only
# fleets, you can override this with a smaller CUDA 12.4/12.6 base.
ARG BASE_IMAGE=runpod/pytorch:2.8.0-py3.11-cuda12.8.1-cudnn-devel-ubuntu22.04

FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1 \
    HF_HUB_ENABLE_HF_TRANSFER=1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      ffmpeg \
      git \
      jq \
      libgl1 \
      libglib2.0-0 \
      rsync \
      wget && \
    rm -rf /var/lib/apt/lists/*

RUN python -m pip install --upgrade pip setuptools wheel

ARG COMFYUI_REPO=https://github.com/comfyanonymous/ComfyUI.git
ARG COMFYUI_REF=master

RUN git clone --filter=blob:none "${COMFYUI_REPO}" /opt/ComfyUI && \
    cd /opt/ComfyUI && \
    git checkout "${COMFYUI_REF}" && \
    python -m pip install -r requirements.txt

COPY requirements-runtime.txt /tmp/requirements-runtime.txt
RUN python -m pip install -r /tmp/requirements-runtime.txt

COPY custom_nodes.txt /tmp/custom_nodes.txt
RUN cd /opt/ComfyUI && \
    while read -r repo ref extra; do \
      [[ -z "${repo}" || "${repo}" == \#* ]] && continue; \
      name="$(basename "${repo}" .git)"; \
      if [[ -n "${ref}" ]]; then \
        git clone --depth 1 --branch "${ref}" "${repo}" "custom_nodes/${name}"; \
      else \
        git clone --depth 1 "${repo}" "custom_nodes/${name}"; \
      fi; \
      if [[ -f "custom_nodes/${name}/requirements.txt" ]]; then \
        python -m pip install -r "custom_nodes/${name}/requirements.txt"; \
      fi; \
    done < /tmp/custom_nodes.txt

COPY config/ /opt/runpod-comfy/config/
COPY scripts/ /opt/runpod-comfy/scripts/
RUN chmod +x /opt/runpod-comfy/scripts/*.sh

WORKDIR /opt/ComfyUI
EXPOSE 8188

CMD ["/opt/runpod-comfy/scripts/start.sh"]
