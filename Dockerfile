# syntax=docker/dockerfile:1.7

# Match the current RunPod ComfyUI stack more closely for output comparison:
# Python 3.12, Torch 2.10, CUDA 12.8.
ARG BASE_IMAGE=pytorch/pytorch:2.10.0-cuda12.8-cudnn9-devel

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

ARG COMFYUI_REPO=https://github.com/comfyanonymous/ComfyUI.git
ARG COMFYUI_REF=v0.18.2

RUN git clone --filter=blob:none "${COMFYUI_REPO}" /opt/ComfyUI && \
    cd /opt/ComfyUI && \
    git checkout "${COMFYUI_REF}" && \
    sed 's/#.*//' requirements.txt | tr -s '[:space:]' '\n' | grep -Ev '^(torch|torchvision|torchaudio)?$' > /tmp/comfyui-requirements-no-torch.txt && \
    python -m pip install -r /tmp/comfyui-requirements-no-torch.txt

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
