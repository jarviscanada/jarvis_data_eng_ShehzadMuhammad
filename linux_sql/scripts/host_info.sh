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

lscpu_out=$(lscpu)

hostname=$(hostname -f)
cpu_number=$(echo "$lscpu_out" | egrep "^CPU\(s\)" | awk '{print $2}' | xargs)
cpu_architecture=$(echo "$lscpu_out" | egrep "^Arch.*" | awk '{print $2}' | xargs)
cpu_model=$(echo "$lscpu_out" | egrep "^Model name:" | awk -F: '{print $2}' | xargs)
cpu_mhz=$(echo "$lscpu_out" | egrep "^Model name:" | sed 's/.*@//' | sed 's/GHz//' | awk '{printf "%.3f", $1 * 1000}' | xargs)
l2_cache=$(echo "$lscpu_out" | egrep "^L2.+" | awk '{print $3}' | xargs)
total_mem=$(vmstat | awk '{print $4}' | tail -1 | xargs)
timestamp=$(vmstat -t | awk '{print $18, $19}' | tail -1 | xargs)

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

#set up env var for pql cmd
export PGPASSWORD=$psql_password
#Insert date into a database
psql -h $psql_host -p $psql_port -d $db_name -U $psql_user -c "$insert_stmt"
exit $?







