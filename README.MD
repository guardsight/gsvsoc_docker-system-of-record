# Synopsis
This package has been created as a way to easily deploy a containerized central logging server. The heirarchy is meant as a modular system. Take what you want and leave what you don't. The logs will be kept on the parent system so they will be maintained and accessible ouside of the docker container.

# Roadmap
See : https://github.com/guardsight/gsvsoc_docker-system-of-record/wiki/Roadmap

# Overview
<p> This is a snapshot to help understand what is going on.
Assume overview is running as a docker service on a physical host or virtual machine.
</p>
<pre>	
						-----------------------------------------
						|										|
			601/TCP		|		-------------					|
			514/UDP		|	 	| Syslog-ng	|					|
		Syslog In --->	| --->	|	Docker	|					|
						|		| Container |					|
						|		-------------					|
						|				|						|
			Flat File	|<--------------|						|
/logs/HOSTS/$IP/$Date/*	|				|						|
						|				|	-------------		|
						|	 			--->|  Optional	|		| Optional Access Calls
						| 					|	Docker	|		| <-------
						|					| Containers|		|
						|					-------------		|
						|					Elastic				|
						|					Kibana				|
						|					Fleet				|
						-----------------------------------------
</pre>
# Hardware Requirements
* Memory : At minimum 8GB of ram. Provision additional RAM as needed.
* Processor : At minimum 4 cores.

# Prerequisites
* Sudo access to a debian linux box
* Internet access to download software
* The instructions below are for an Ubuntu 16+ distribution, they can be modified for a CentOS installation.

# Installation

## Install Dependencies

1. Install latest updates and docker
	1. <code> sudo apt update </code>
	1. <code> sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common </code>
	1. <code> curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - </code>
	1. <code> sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs)  stable"</code>
	1. <code> sudo apt update </code>
	1. <code> sudo apt-get install -y docker-ce </code>
1. Install Docker Compose
	1. <code> sudo curl -L "https://github.com/docker/compose/releases/download/1.26.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose </code>
	1. <code> sudo chmod +x /usr/local/bin/docker-compose </code>
1. Prep directories
	1. <code> sudo mkdir -p /opt/secops </code>
	1. <code> sudo mkdir -p /logs/HOSTS </code>

1. Install git and jq
	1. <code> sudo apt install -y git jq </code>

## Configuration
1. Make sure you have enough vm mappings available
	1. <code> sudo sysctl -w vm.max_map_count=262144</code>

## Set up permissions
1. Create a local logs group
	1. <code> sudo groupadd -g 1111 logs </code>
1. Create a local user and add to logs group
	1. <code> sudo useradd -u 1111 -g 1111 logs </code>
1. Change ownership and permisisons of /logs and /opt/secops directories
	1. <code> sudo chown -R logs:logs /logs </code>
	1. <code> sudo chmod -R 750 /logs </code>
	1. <code> sudo chown logs:logs /opt/secops </code>
	1. <code> sudo chmod 770 /opt/secops </code>
	1. <code> sudo usermod -aG logs $(whoami)</code>
1. Refresh user groups
	1. <code>newgrp logs</code>
	1. Note: if this is an issue, log off the machine and log back on.

## Download Package
1. <code> cd /opt/secops </code>
1. <code> git clone https://github.com/guardsight/gsvsoc_docker-system-of-record.git </code>
1. <code> cd /opt/secops/gsvsoc_docker-system-of-record </code>

## Copy PreBuilt Helper Scripts
1. Add script file to profile.d
	1. <code>sudo cp /opt/secops/gsvsoc_docker-system-of-record/99-infosec.sh /etc/profile.d/</code>
	1. <code>sudo chmod +x /etc/profile.d/99-infosec.sh</code>

## Customize
1. Open and modify the sections in create_docker_compose.sh, then run it
1. This is a required step, regardless of customization
1. <code>./create_docker_compose.sh</code>

## Build and Start
1. <code> cd /opt/secops/gsvsoc_docker-system-of-record </code>
1. <code> sudo docker-compose -p 'gsvsoc-system-of-record' up --build -d </code>
1. The service should be up within 20 seconds

## Stop Container
1. <code> cd /opt/secops/gsvsoc_docker-system-of-record </code>
1. <code> sudo docker-compose -p 'gsvsoc-system-of-record' down </code>

## Clean up Containers
1. <code> cd /opt/secops/gsvsoc_docker-system-of-record </code>
1. <code> bash docker-cleanup.sh </code>

## Update
1. <code> cd /opt/secops/gsvsoc_docker-system-of-record </code>
1. <code> sudo docker-compose -p 'gsvsoc-system-of-record' down </code>
1. <code> bash docker-cleanup.sh </code>
1. <code> git pull </code>
1. <code> sudo docker-compose -p 'gsvsoc-system-of-record' up --build -d </code>
1. The service should be up within 20 seconds

# Usage

## Raw logs
<p> The logs are stored in /logs/HOSTS/{HOST}/{DATE}/messages.log[.gz]<br>
You can zgrep through these logs and correlate or filter down the data you want<br>
NOTE: This data will be there until the data is moved or purged.
</p>


# Scheduled Tasks
1. /etc/cron.daily/GSVSOC-logs-compress.sh
	1. Runs daily and compresses the messages.log files in /logs/HOSTS

# Debugging
## Follow container logs
1. <code> sudo docker logs --follow syslog-ng</code>

## Test Case
1. The following is meant to be run from the parent machine
1. <code> echo "testing_tcp"  | nc -w1 127.0.0.1 614  </code>
1. <code> echo "testing_udp" | nc -u -w1 127.0.0.1 514 </code>
1. Wait at least 20 seconds, and then verify the log has appeared
1. Check raw logs for existence
	1. <code> zgrep -E "testing_((tcp)|(udp))" /logs/HOSTS/\*/"$(date +'%F')"/\* </code>

# See
* Instruction:W-0021_-_How-To_Create_A_Syslog_Infrastructure
