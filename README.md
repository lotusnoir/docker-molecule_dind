# Docker Image with Debian 13 - Trixie base image

This repo was created in order to test ansible roles with molecule.

## Build it locally

docker build - < Dockerfile
docker build -t test-build-dind .
docker run -d --privileged \
 --name test-dind \
 --cgroupns=host \
 -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
 test-build-dind

## Use it from dockerhub

    https://hub.docker.com/repository/docker/lotusnoir/ansible_molecule_test_images:debian13
