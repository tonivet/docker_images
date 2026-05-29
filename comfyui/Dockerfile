# Base image with system dependencies
FROM nvidia/cuda:12.8.1-cudnn-runtime-ubuntu24.04

# Set environment variables to avoid tzdata prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Sofia

# Install system dependencies
RUN apt-get update --allow-releaseinfo-change && \
    apt-get install -y software-properties-common && \
    add-apt-repository universe && \
    apt-get update && \
    apt-get install -y \
        git \
        curl \
        wget \
        vim \
        ca-certificates \
        build-essential \
        python3 \
        python3-pip \
        python3-venv \
        libgl1 \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxrender-dev \
        libgomp1 \
        tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone the ComfyUI repository
RUN git clone https://github.com/comfyanonymous/ComfyUI.git .

# Create a Python virtual environment and install dependencies
RUN python3 -m venv /app/venv && \
    /app/venv/bin/pip install --upgrade pip

RUN /app/venv/bin/pip install --pre \
    torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/nightly/cu128

# Install xformers
RUN /app/venv/bin/pip install -U xformers

# Install Comfyui
RUN /app/venv/bin/pip install -r requirements.txt

# Expose ComfyUI internal port
EXPOSE 8188

# Check for previous installed coustom_nodes if not install ComfyUI-Manager else install previous installed custom nodes dependencies. Starts ComfyUI
CMD [ ! -d /app/custom_nodes/ComfyUI-Manager ] && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git /app/custom_nodes/ComfyUI-Manager || true; \
    find /app/custom_nodes -name requirements.txt -exec /app/venv/bin/pip install -r {} \; && \
    exec /app/venv/bin/python3 main.py --listen 0.0.0.0 --port 8188
