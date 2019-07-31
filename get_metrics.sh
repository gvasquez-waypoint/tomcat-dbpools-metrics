#!/bin/bash

hostname=$(hostname);
user=waypoint;
pass=waypoint;

aws_path=/usr/local/bin/aws;
aws_region="us-west-1";

cw_namespace="Tomcat DB Pool";
cw_metric_name="Utilization";

put_cw_metric() {
   pool=$1;
   value=$2;
   echo "value" "$value";
   $aws_path cloudwatch put-metric-data  --region=$aws_region --metric-name "$cw_metric_name" --namespace "$cw_namespace" --dimensions "hostname=$hostname,pool=$pool" --value "$value";
}

get_jmx_val() {
	clean=255;
	jdbcval=$1;
   att=$2;
   val=$(curl -s -u $user:$pass -X GET  http://localhost:8080/manager/jmxproxy --data-urlencode get=Catalina:type=DataSource,class=javax.sql.DataSource,name="${jdbcval}" -d att="${att}" -G);
   #echo "8 $val";
   if [[ $val == OK* ]]; then
	   IFS=', ' read -r -a array <<< "$val";
	   len=${#array[@]};
	   clean=${array[$((len-1))]};	   
	   echo "$clean";
   fi
   echo "clean: $clean";
   return "$clean";
}

get_jmx() {
   get_jmx_val "$1" "maxActive";
   maxActive=$?;
   echo "maxActive: $maxActive";
   if [[ $maxActive == 255 ]]; then
	   echo "retry";
      get_jmx_val "$1" "maxTotal";
      maxActive=$?;   
   fi
   get_jmx_val "$1" "active";
   active=$?;
      if [[ $active == 255 ]]; then
	      	   echo "retry";
		         get_jmx_val "$1" "numActive";
			       active=$?;   
			          fi
   used=$((100*active/maxActive));
   echo $used;
   put_cw_metric "$1" "$used";
}

while read -r line; do 
   name=$(cut -d',' -f3 <<<"$line");
   tmp=$(cut -d'=' -f2 <<<"$name");
   jdbc=${tmp//[[:space:]]/};
   echo "iter $jdbc";
   get_jmx "$jdbc";
   ##break;
done < <( curl -s -u $user:$pass -X GET  http://localhost:8080/manager/jmxproxy --data-urlencode qry="Catalina:type=DataSource,class=javax.sql.DataSource,name=*"|grep '^Name: Catalina:type=DataSource,class=javax.sql.DataSource,name=".*"[[:cntrl:]]*$')
