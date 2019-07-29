# tomcat-dbpools-metrics
Get Tomcat's Database Pools utilization metrics


If you have several Apache Tomcat instances, have you ever wondered how their database connection pool are behaving? Last we had an outage in our of our services, due to a under estimated connection pool so, we had the motivation to gain observability on these resources's metrics, initially at least active and maximum configured connections per pool.

Currently have pools only for PostgreSQL and HSQL so, so those will be the cases considered our our first approach.
