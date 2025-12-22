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

# Helper function to extract a field from lscpu
get_lscpu_field() {
    local pattern=$1
    local col=$2
    echo "$lscpu_out" | grep -E "$pattern" | awk "{print \$$col}" | xargs
}

lscpu_out=$(lscpu)

hostname=$(hostname -f)
cpu_number=$(get_lscpu_field "^CPU\\(s\\)" 2)
cpu_architecture=$(get_lscpu_field "^Arch.*" 2)
cpu_model=$(echo "$lscpu_out" | grep -E "^Model name:" | awk -F: '{print $2}' | xargs)
cpu_mhz=$(echo "$cpu_model" | sed 's/.*@//' | sed 's/GHz//' | awk '{printf "%.3f", $1 * 1000}')
l2_cache=$(get_lscpu_field "^L2.+" 3)
total_mem=$(vmstat | awk '{print $4}' | tail -1 | xargs)
timestamp=$(vmstat -t | awk '{print $18, $19}' | tail -1 | xargs)

# Insert into PostgreSQL
insert_stmt="INSERT INTO host_info(
  \"timestamp\",
  total_mem,
  l2_cache,
  cpu_mhz,
  cpu_model,
  cpu_architecture,
  cpu_number,
  hostname
) VALUES (
  '$timestamp',
  '$total_mem',
  '$l2_cache',
  '$cpu_mhz',
  '$cpu_model',
  '$cpu_architecture',
  '$cpu_number',
  '$hostname'
);"

export PGPASSWORD=$psql_password
psql -h "$psql_host" -p "$psql_port" -d "$db_name" -U "$psql_user" -c "$insert_stmt"
exit $?
