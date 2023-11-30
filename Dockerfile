# syntax=docker/dockerfile:1
FROM tomcat:9.0.76-jdk21-openjdk-slim
# Install the XProc-Z servlet
COPY xproc-z.war /xproc-z.war
# Copy the Tomcat configuration file which registers the proxy and harvester XProc pipelines as
# two distinct instances of the xproc-z.war web app
COPY tomcat-config/proxy.xml /usr/local/tomcat/conf/Catalina/localhost/
COPY tomcat-config/harvester.xml /usr/local/tomcat/conf/Catalina/localhost/
COPY harvest /var/lib/harvest
# copy the XProc and XSLT source code of the proxy service
COPY src /src
# Tomcat is listening on port 8080
EXPOSE 8080/tcp
