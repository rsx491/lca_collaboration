Read Me File -> Development

On initial/first intall or to add repos "DB_INSTALL=yes" environment value will need to be set to "yes"
After that please set this value to "no"

cd {to the directory}

docker build -t lca-server .
docker-compose up -d

update user set password='$2a$10$3D.y4iBojRxrxC6WdoG5A.qGeuM1u4e6lIEOQL1kQ4jryBxmK7p2y' where username='admin';
