Read Me File -> Development


cd {to the directory}

docker build -t lca-server .
docker-compose up -d

update user set password='$2a$10$3D.y4iBojRxrxC6WdoG5A.qGeuM1u4e6lIEOQL1kQ4jryBxmK7p2y' where username='admin';

run this command
curl --location --request PUT 'http://localhost:9200/collaboration-server' \
--header 'Content-Type: application/json' \
--data ' {
          "mappings": {
            "properties": {}
          }
        }'

Steps to Enable open-serach

1. Login in to admin dashboard 
2. go to settings

enable 
    Search: Users can search for data sets within repositories they have access to
    Flow usage: Enables analysis and display of flow usage

Opensearch settings
change host name to opensearch-node1
Then run test
THis should give a success message
