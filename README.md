# tomcat-dbpools-metrics
Get Tomcat's Database Pools utilization metrics

If you have several [Apache Tomcat](http://tomcat.apache.org/) instances, have you ever wondered how their database connection pool are behaving? Last we had an outage in our of our services, due to a under estimated connection pool so, we had the motivation to gain observability on these resources' metrics, initially at least **active** and **maximum** configured connections per pool.

Currently we have pools only for [PostgreSQL](https://www.postgresql.org/) and [HSQLDB](http://hsqldb.org/) so, those will be the cases considered in our first approach.

## Metrics How-To

Approach taken: [JMXProxy](https://tomcat.apache.org/tomcat-8.0-doc/monitoring.html#Using_the_JMXProxyServlet)

Initial draft shell script
~~~~
#!/bin/bash 
getJmxVal() { 
        jdbcval=$1; 
   att=$2; 
   val=$(curl -s -u waypoint:waypoint -X GET  http://localhost:8080/manager/jmxproxy --data-urlencode get=Catalina:type=DataSource,class=javax.sql.DataSource,name="${jdbcval}" -d att="${att}" -G); 
   echo "8 $val"; 
   if [[ $val == OK* ]]; then 
           IFS=', ' read -r -a array <<< "$val"; 
           len=${#array[@]}; 
           clean=${array[$((len-1))]};      
           echo "$clean"; 
           return $clean; 
   fi 
} 
 
getJmx() { 
   getJmxVal "$1" "maxActive"; 
   maxActive=$?; 
   getJmxVal "$1" "active"; 
   active=$?; 
   used=$((100*active/maxActive)); 
   echo $used; 
} 
 
while read -r line; do  
   name=$(cut -d',' -f3 <<<"$line"); 
   tmp=$(cut -d'=' -f2 <<<"$name"); 
   jdbc=${tmp//[[:space:]]/}; 
   getJmx "$jdbc"; 
   break; 
done < <( curl -s -u waypoint:waypoint -X GET  http://localhost:8080/manager/jmxproxy|grep "Name: Catalina:type=DataSource,class=javax.sql.DataSource,name"|grep -v jmxName|grep -v connectionpool)
~~~~
