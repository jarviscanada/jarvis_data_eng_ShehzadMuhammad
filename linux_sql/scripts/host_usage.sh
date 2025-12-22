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

# Helper function to extract last value from a command
get_last_value() {
    # Usage: get_last_value "command" column_number (optional)
    local cmd="$1"
    local col="$2"
    if [ -z "$col" ]; then
        eval "$cmd" | tail -1 | xargs
    else
        eval "$cmd" | awk "{print \$$col}" | tail -1 | xargs
    fi
}

hostname=$(hostname -f)

memory_free=$(get_last_value "vmstat --unit M" 4)
cpu_idle=$(get_last_value "vmstat --unit M" 15)
cpu_kernel=$(get_last_value "vmstat --unit M" 14)
disk_io=$(get_last_value "vmstat -d" 10)
disk_available=$(get_last_value "df -BM /" 4 | sed 's/M//')
timestamp=$(date '+%Y-%m-%d %H:%M:%S')

host_id="(SELECT id FROM host_info WHERE hostname='$hostname')"

# Insert into PostgreSQL
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

export PGPASSWORD=$psql_password
psql -h $psql_host -p $psql_port -d $db_name -U $psql_user -c "$insert_stmt"
exit $?
