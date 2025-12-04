#!/bin/bash

# Capture CLI Arguments
psql_host=$1
psql_port=$2
db_name=$3
psql_user=$4
psql_password=$5

if [ "$#" -ne 5 ]; then
  echo "Illegal number of arguments"
  exit 1
fi

vmstat_mb=$(vmstat --unit M)
hostname=$(hostname -f)

# Retrieve hardware specification variables
memory_free=$(echo "$vmstat_mb" | awk '{print $4}'| tail -1 | xargs)
cpu_idle=$(echo "$vmstat_mb" | awk '{print $15}' | tail -1 | xargs)
cpu_kernel=$(echo "$vmstat_mb" | awk '{print $14}' | tail -1 | xargs)
disk_io=$(vmstat -d | awk '{print $10}' | tail -1 | xargs)
disk_available=$(df -BM / | awk '{print $4}' | tail -1 | sed 's/M//' | xargs)
timestamp=$(vmstat -t | awk '{print $18, $19}' | tail -1 | xargs)

host_id="(SELECT id FROM host_info WHERE hostname='$hostname')";


insert_stmt="INSERT INTO host_usage(
  \"timestamp\",
  disk_available,
  disk_io,
  cpu_kernel,
  cpu_idle,
  memory_free,
  host_id
) VALUES (
  '$timestamp',
  '$disk_available',
  '$disk_io',
  '$cpu_kernel',
  '$cpu_idle',
  '$memory_free',
  $host_id
);"

#set up env var for pql cmd
export PGPASSWORD=$psql_password
#Insert date into a database
psql -h $psql_host -p $psql_port -d $db_name -U $psql_user -c "$insert_stmt"
exit $?



