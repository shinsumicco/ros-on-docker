#!/bin/bash

SCRIPT_DPATH=$(cd $(dirname ${0}); pwd)

ROS_DISTRO=galactic

CONTAINER_USER=user
CONTAINER_HOME=/home/${CONTAINER_USER}

HOST_PROJECT_DPATH=${SCRIPT_DPATH}/ros-on-docker
CONTAINER_PROJECT_DPATH=/home/user/ros-on-docker

export DISPLAY=${DISPLAY:-:0.0}
xrandr > /dev/null 2>&1
if [ ${?} != 0 ]
then
  echo "invalid display number: ${DISPLAY}"
  exit 1
fi

HOST_UID=$(id -u)
HOST_GID=$(id -g)

xhost +local: > /dev/null 2>&1

docker run --rm -it --ipc host --net host --runtime nvidia \
  --name ros-${ROS_DISTRO}-desktop-$(whoami)-$(uuidgen | cut -c 1-8) \
  -v ${HOST_PROJECT_DPATH}:${CONTAINER_PROJECT_DPATH}:rw \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -e NVIDIA_VISIBLE_DEVICES=all \
  -e NVIDIA_DRIVER_CAPABILITIES=all \
  -e CONTAINER_PROJECT_DPATH=${CONTAINER_PROJECT_DPATH} \
  -e DISPLAY=${DISPLAY} -e HOST_UID=${HOST_UID} -e HOST_GID=${HOST_GID} \
  "${@}" \
  ros-${ROS_DISTRO}-desktop /bin/bash
