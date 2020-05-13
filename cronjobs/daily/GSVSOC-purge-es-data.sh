#!/bin/bash
#
# NAME - GSVSOC-purge-es-data
#
# SYNOPSIS
# GSVSOC-purge-es-data
#
# DESCRIPTION
# purges data older than 30 days in elastic search
#
# AUTHOR
# vsoc@guardsight.com
#
# LICENSE
# GPLv3
# (c) GuardSight, Inc. 2019
#
/bin/curl -XDELETE http://127.0.0.1:9200/gsvsoc-es-$(date '+%F' --date='31 days ago')
