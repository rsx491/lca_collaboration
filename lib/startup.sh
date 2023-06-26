#!/bin/bash
if [[ $DB_INSTALL = "yes" ]]
then
java -jar /opt/cs/misc/collaboration-server-migration-2.0.0-jar-with-dependencies.jar /opt/cs/misc/lca-collaboration-installer-2.0.0.config
else
echo "DB Installation skipped using ENV variable. If you want to install fresh DB mark DB_INSTALL as yes."
fi
/var/lib/tomcat9/bin/startup.sh run