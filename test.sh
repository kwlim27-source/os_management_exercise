#!/bin/bash

# Configuration thresholds
DISK_THRESHOLD=80
MEM_THRESHOLD=75
REPORT_FILE="system_health_$(date +%Y-%m-%d).log"

echo "==========================================" >> "$REPORT_FILE"
echo "System Health Report - $(date)" >> "$REPORT_FILE"
echo "Host: $(hostname) | User: $USER" >> "$REPORT_FILE"
echo "==========================================" >> "$REPORT_FILE"

# 1. Monitor Disk Usage using df and AWK
echo -e "\n[1] DISK USAGE CHECK:" >> "$REPORT_FILE"
df -h | awk -v thresh="$DISK_THRESHOLD" '
NR>1 && $1 ~ /^\/dev/ {
    gsub(/%/, "", $5); # Strip the % sign to compare as a number
    if ($5 >= thresh) {
        print "ALERT: Partition " $6 " is at " $5 "% capacity!"
    } else {
        print "OK: Partition " $6 " is at " $5 "% capacity."
    }
}' >> "$REPORT_FILE"

# 2. Monitor Memory Usage using free and AWK
echo -e "\n[2] MEMORY USAGE CHECK:" >> "$REPORT_FILE"
free -m | awk -v thresh="$MEM_THRESHOLD" '
NR==2 {
    used_pct = ($3 / $2) * 100;
    printf "RAM Used: %dMB / %dMB (%.1f%%)\n", $3, $2, used_pct;
    if (used_pct >= thresh) {
        print "ALERT: High memory consumption detected!"
    }
}' >> "$REPORT_FILE"

# 3. Top 3 Memory-Consuming Processes using ps and AWK
echo -e "\n[3] TOP 3 MEMORY PROCESSES:" >> "$REPORT_FILE"
ps -eo pid,comm,%mem,%cpu --sort=-%mem | awk '
NR==1 { printf "%-8s %-20s %-8s %-8s\n", $1, $2, $3, $4 }
NR>=2 && NR<=4 { printf "%-8s %-20s %-8s %-8s\n", $1, $2, $3"%", $4"%" }
' >> "$REPORT_FILE"

echo -e "\nReport saved to $REPORT_FILE"
cat "$REPORT_FILE"
