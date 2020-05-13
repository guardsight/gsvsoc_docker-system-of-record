#!/bin/bash

docker container kill gsvsoc-syslog-stack
docker container rm gsvsoc-syslog-stack
docker container kill gsvsoc-syslog-stack_kibana_1
docker container rm gsvsoc-syslog-stack_kibana_1
docker container kill elastic-container-1
docker container rm elastic-container-1
