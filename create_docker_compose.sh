#!/bin/bash

/bin/echo "version: '3.2'
services:" | /usr/bin/tee docker-compose.yml

# Beta for Syslog-ng as opposed to logstash
# # Add Docker instance to compose file
# /bin/cat system-of-record.yml | /usr/bin/tee -a docker-compose.yml
# /bin/echo -e "\n" | /usr/bin/tee -a docker-compose.yml

# Add Elastic
/bin/cat elasticsearch.yml | /usr/bin/tee -a docker-compose.yml
/bin/echo -e "\n" | /usr/bin/tee -a docker-compose.yml

# Add Kibana
/bin/cat kibana.yml | /usr/bin/tee -a docker-compose.yml
/bin/echo -e "\n" | /usr/bin/tee -a docker-compose.yml

# Add Logstash
/bin/cat logstash.yml | /usr/bin/tee -a docker-compose.yml
/bin/echo -e "\n" | /usr/bin/tee -a docker-compose.yml

# Add fleet
# /bin/cat fleet.yml | /usr/bin/tee -a docker-compose.yml
# /bin/echo -e "\n" | /usr/bin/tee -a docker-compose.yml


# Add volume instances
/bin/cat volumes.yml | /usr/bin/tee -a docker-compose.yml
/bin/echo -e "\n" | /usr/bin/tee -a docker-compose.yml

# Add network instances
/bin/cat networks.yml | /usr/bin/tee -a docker-compose.yml
/bin/echo -e "\n" | /usr/bin/tee -a docker-compose.yml