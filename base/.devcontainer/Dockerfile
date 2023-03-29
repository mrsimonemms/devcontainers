# Based on the Gitpod base image
# @link https://github.com/gitpod-io/workspace-images/blob/main/base/Dockerfile

FROM --platform=${TARGETPLATFORM:-linux/amd64} mcr.microsoft.com/vscode/devcontainers/base:ubuntu

USER root

# Base
RUN apt-get update \
  && apt-get -y install \
  bash-completion \
  build-essential \
  emacs-nox \
  fish \
  git \
  git-core \
  git-lfs \
  htop \
  iputils-ping \
  jq \
  less \
  locales \
  lsof \
  man-db \
  multitail \
  nano \
  ninja-build \
  ripgrep \
  software-properties-common \
  ssl-cert \
  stow \
  sudo \
  time \
  unzip \
  vim \
  zip \
  zsh \
  && locale-gen en_GB.UTF-8

ENV LANG=en_GB.UTF-8

# Update packages
RUN apt-get -y autoremove \
  && apt-get -y autoclean \
  && apt-get -y clean
RUN rm -rf \
  /var/cache/debconf/* \
  /var/lib/apt/lists/* \
  /tmp/* \
  /var/tmp/*

# Configure git-lfs
RUN git lfs install --system --skip-repo

# Install diff-so-fancy
# @link https://github.com/so-fancy/diff-so-fancy
RUN add-apt-repository ppa:aos1/diff-so-fancy \
  && apt-get update \
  && apt-get install -y diff-so-fancy

USER vscode
WORKDIR /home/vscode

RUN { echo && echo "PS1='\[\033[01;32m\]\u\[\033[00m\] \[\033[01;34m\]\w\[\033[00m\]\$(__git_ps1 \" (%s)\") $ '" ; } >> $HOME/.bashrc

COPY --chown=vscode:vscode bash_aliases .bash_aliases
COPY --chown=vscode:vscode gitconfig .config/git/config

# Custom PATH additions
ENV PATH=$HOME/.local/bin:$PATH

WORKDIR /code
