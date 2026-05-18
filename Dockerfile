# syntax=docker/dockerfile:1.7

# Verification image: inherit RunPod's ComfyUI stack directly, then replace only
# startup/model-download behavior with this repo's lightweight RunPod flow.
ARG BASE_IMAGE=runpod/comfyui:latest

FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    HF_HUB_ENABLE_HF_TRANSFER=1 \
    COMFYUI_DIR=/opt/comfyui-baked

COPY config/ /opt/runpod-comfy/config/
COPY scripts/ /opt/runpod-comfy/scripts/
RUN chmod +x /opt/runpod-comfy/scripts/*.sh

WORKDIR /opt/comfyui-baked
EXPOSE 8188

ENTRYPOINT ["/opt/runpod-comfy/scripts/start.sh"]
