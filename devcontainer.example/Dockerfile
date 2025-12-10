FROM frappe/bench:latest

# Container version labels for runtime identification
LABEL devcontainer.version="1.0.0"
LABEL devcontainer.template="dartwing-frappe-devcontainer-1.0.0"
LABEL devcontainer.description="Dartwing Frappe App Development Container"
LABEL devcontainer.created="2025-11-16T00:00:00Z"

# Switch to root to install system packages
USER root


# ========================================
# TOOLING SETUP - Various dev tools
# ========================================

# Install additional development tools
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    git \
    vim \
    nano \
    curl \
    wget \
    jq \
    iputils-ping \
    net-tools \
    sudo \
    zsh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js (LTS version)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Python development tools
RUN pip install --upgrade pip \
    && pip install \
    black \
    flake8 \
    isort \
    pylint \
    pytest \
    ipython


# ========================================
# BENCH SETUP - only verify
# ========================================

# 1. Switch to the correct user immediately
USER frappe

# 2. Set the working directory to where bench expects to be
WORKDIR /home/frappe/bench

# Verify everything is there (optional, but good for peace of mind)
RUN bench --version && python3 --version && pip --version


# ========================================
# USER SETUP - Match host UID/GID
# ========================================

# Switch back to root for user management
USER root

# Build arguments for user management
# These are passed from docker-compose.yml and match the host user
ARG USERNAME
ARG USER_UID
ARG USER_GID

# Remove any existing user/group with the target UID/GID and create new user
# This ensures we match the host user exactly, replacing the default 'frappe' user
RUN set -eux && \
    # Remove existing user with target UID if exists
    if getent passwd "$USER_UID" >/dev/null; then \
    existing_user=$(getent passwd "$USER_UID" | cut -d: -f1) && \
    userdel --force --remove $existing_user 2>/dev/null || true; \
    fi && \
    # Handle existing group with target GID
    if getent group "$USER_GID" >/dev/null; then \
    existing_group=$(getent group "$USER_GID" | cut -d: -f1) && \
    groupmod -n $USERNAME $existing_group 2>/dev/null || true; \
    else \
    groupadd --gid $USER_GID $USERNAME 2>/dev/null || true; \
    fi && \
    # Create new user if it doesn't exist
    if ! getent passwd "$USERNAME" >/dev/null; then \
    useradd --uid $USER_UID --gid $USERNAME -m -s /bin/zsh $USERNAME 2>/dev/null || true; \
    fi && \
    echo $USERNAME ALL=\(ALL\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME


# ========================================
# AI SETUP - Spec-Kit and OpenSpec
# ========================================

# Install uv (fast Python package installer) as user
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install spec-kit using uv (installed to ~/.local/bin)
RUN $HOME/.local/bin/uv tool install specify-cli --force --from git+https://github.com/github/spec-kit.git

# Install OpenSpec to user-local npm directory
RUN npm install -g @fission-ai/openspec@latest


# ========================================
# USER SETUP - Install and config zsh
# ========================================

# Add bench and uv tools to PATH
RUN echo 'export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"' >> ~/.bashrc && \
    echo 'export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"' >> ~/.zshrc

# Install Oh My Zsh for better developer experience
USER $USERNAME
RUN curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh -s -- --unattended || \
    echo "Oh My Zsh installation failed, using default zsh"

# Install Oh My Zsh plugins
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/plugins/zsh-syntax-highlighting

# Configure npm to use user-local directory for global installs
RUN mkdir -p $HOME/.npm-global && \
    npm config set prefix $HOME/.npm-global && \
    echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc && \
    echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.zshrc

# Override bash profile to run zsh instead of bash
RUN echo '# Force zsh when bash is requested' >> ~/.bash_profile && \
    echo 'if [ -n "$PS1" ] && [ -z "$ZSH_VERSION" ]; then' >> ~/.bash_profile && \
    echo '    exec /bin/zsh -l' >> ~/.bash_profile && \
    echo 'fi' >> ~/.bash_profile && \
    echo '' >> ~/.bash_profile && \
    echo '# Fallback: source bashrc if we somehow end up in bash' >> ~/.bash_profile && \
    echo '[ -f ~/.bashrc ] && source ~/.bashrc' >> ~/.bash_profile

# Safety command: Ensure the user shell is set to zsh
USER root
RUN chsh -s /bin/zsh $USERNAME

# Create workspace directories with proper ownership
RUN mkdir -p /workspace/development && \
    chown -R $USERNAME:$USERNAME /workspace

# Switch back to user
USER $USERNAME

# Set working directory
WORKDIR /workspace

# Default command
CMD ["sleep", "infinity"]
