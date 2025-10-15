#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# Licensed Materials - Property of IBM
# 5747-SM3
# (c) Copyright IBM Corp. 2017, 2021  All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
import subprocess
import re

# Get process info
ps = subprocess.Popen(['ps', '-caxm', '-orss,comm'], stdout=subprocess.PIPE).communicate()[0]
vm = subprocess.Popen(['vm_stat'], stdout=subprocess.PIPE).communicate()[0]

processLines = ps.split('\n')
sep = re.compile('[\s]+')
rssTotal = 0
for row in range(1,len(processLines)):
    rowText = processLines[row].strip()
    rowElements = sep.split(rowText)
    try:
        rss = float(rowElements[0]) * 1024
    except:
        rss = 0
    rssTotal += rss

vmLines = vm.split('\n')
sep = re.compile(':[\s]+')
vmStats = {}
for row in range(1,len(vmLines)-2):
    rowText = vmLines[row].strip()
    rowElements = sep.split(rowText)
    vmStats[(rowElements[0])] = int(rowElements[1].strip('\.')) * 4096

print 'Wired Memory:\t\t%dMB' % ( vmStats["Pages wired down"]/1024/1024 )
print 'Active Memory:\t\t%dMB' % ( vmStats["Pages active"]/1024/1024 )
print 'Inactive Memory:\t%dMB' % ( vmStats["Pages inactive"]/1024/1024 )
print 'Free Memory:\t\t%dMB' % ( vmStats["Pages free"]/1024/1024 )
print 'Real Mem Total (ps):\t%.0fGB' % ( rssTotal/1024/1024/1024 )
