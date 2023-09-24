FROM nvidia/opengl:1.2-glvnd-devel-ubuntu20.04

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NOWARNINGS yes

# install minumum packages
RUN set -x && \
  apt-get update -yq && \
  apt-get upgrade -yq --no-install-recommends && \
  apt-get install -yq --no-install-recommends \
    sudo \
    gosu \
    curl \
    wget \
    dirmngr \
    gnupg2 \
    lsb-release \
    ca-certificates \
    software-properties-common \
    git \
    vim \
    bash-completion && \
  apt-get autoremove -yq && \
  apt-get clean -yq && \
  rm -rf /var/lib/apt/lists/*

# install CUDA
RUN set -x && \
  wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.0-1_all.deb && \
  dpkg -i cuda-keyring_1.0-1_all.deb && \
  rm -rf cuda-keyring_1.0-1_all.deb && \
  apt-get update -yq && \
  apt-get upgrade -yq --no-install-recommends && \
  apt-get install -yq --no-install-recommends \
    cuda-compiler-11-4 && \
  apt-get autoremove -yq && \
  apt-get clean -yq && \
  rm -rf /var/lib/apt/lists/*

# install ROS packages
ARG ROS_DISTRO=galactic
RUN set -x && \
  curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null && \
  apt-get update -yq && \
  apt-get upgrade -yq --no-install-recommends && \
  apt-get install -yq --no-install-recommends \
    ros-${ROS_DISTRO}-desktop \
    python3-colcon-common-extensions \
    python3-rosdep && \
  apt-get autoremove -yq && \
  apt-get clean -yq && \
  rm -rf /var/lib/apt/lists/*

# update ROS packages
RUN set -x && \
  apt-get update -yq && \
  rosdep init && \
  rosdep update --include-eol-distros && \
  apt-get autoremove -yq && \
  apt-get clean -yq && \
  rm -rf /var/lib/apt/lists/*

# add new sudo user
ENV CONTAINER_USER user
ENV CONTAINER_HOME /home/${CONTAINER_USER}
ARG CONTAINER_UID=9000
ARG CONTAINER_GID=9000
RUN set -x && \
  useradd -m ${CONTAINER_USER} && \
  echo "${CONTAINER_USER}:${CONTAINER_USER}" | chpasswd && \
  usermod --shell /bin/bash ${CONTAINER_USER} && \
  usermod -aG sudo ${CONTAINER_USER} && \
  mkdir -p /etc/sudoers.d && \
  echo "${CONTAINER_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${CONTAINER_USER} && \
  chmod 0440 /etc/sudoers.d/${CONTAINER_USER} && \
  usermod -u ${CONTAINER_UID} ${CONTAINER_USER} && \
  groupmod -g ${CONTAINER_GID} ${CONTAINER_USER} && \
  touch ${CONTAINER_HOME}/.sudo_as_admin_successful

# apply entrypoint
COPY entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
