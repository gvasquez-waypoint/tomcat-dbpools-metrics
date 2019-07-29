# tomcat-dbpools-metrics
Get Tomcat's Database Pools utilization metrics

If you have several [Apache Tomcat](http://tomcat.apache.org/) instances, have you ever wondered how their database connection pool are behaving? Last we had an outage in our of our services, due to a under estimated connection pool so, we had the motivation to gain observability on these resources' metrics, initially at least **active** and **maximum** configured connections per pool.

Currently we have pools only for [PostgreSQL](https://www.postgresql.org/) and [HSQLDB](http://hsqldb.org/) so, those will be the cases considered in our first approach.

## Metrics How-To

Approach taken: [JMXProxy](https://tomcat.apache.org/tomcat-8.0-doc/monitoring.html#Using_the_JMXProxyServlet)

Initial draft shell script
~~~~
getJmxVal () {
   jdbc=$1;
   att=$2;
   echo "jdbc: " $jdbc;
   echo "att: " $att;
   val=$(curl -s -v -u waypoint:waypoint -X GET  http://localhost:8080/manager/jmxproxy --data-urlencode get=Catalina:type=DataSource,class=javax.sql.DataSource,name=${jdbc} -d att=${att} -G);
   echo $val;
   if [[ $val == OK* ]]
then
echo $val;
fi
}

getJmx () {
   echo "jdbc in: " $jdbc "test"
   getJmxVal $jdbc "maxActive";
   getJmxVal $jdbc "active";
}

while read line; do name=$(cut -d',' -f3 <<<$line); jdbc=$(cut -d'=' -f2 <<<$name; echo $jdbc; getJmx '$jdbc'; break; done < <( curl -s -u waypoint:waypoint -X GET  http://localhost:8080/manager/jmxproxy|grep "Name: Catalina:type=DataSource,class=javax.sql.DataSource,name"|grep -v jmxName|grep -v connectionpool)
~~~~
