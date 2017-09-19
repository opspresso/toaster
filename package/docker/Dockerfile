# Dockerfile

FROM java:8

MAINTAINER toast@yanolja.com

VOLUME ["/data/apps"]
VOLUME ["/data/logs"]

EXPOSE 8080

ADD ROOT.jar /data/apps/

CMD ["java", "-jar", "/data/apps/ROOT.jar"]
