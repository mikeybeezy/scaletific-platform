
docker run -d \
--name mysql \
--net wordpress \
-e MYSQL_DATABASE=exampledb \
-e MYSQL_USER=exampleuser \
-e MYSQL_PASSWORD=examplepassword \
-e MYSQL_RANDOM_ROOT_PASSWORD=1 \
-v ${PWD}/data:/var/lib/mysql \
 wordpress-mysqldb:1.3


 docker run -d \
--rm \
-p 80:80 \
--name wordpress \
--net wordpress \
-e WORDPRESS_DB_HOST=mysql \
-e WORDPRESS_DB_USER=exampleuser \
-e WORDPRESS_DB_PASSWORD=examplepassword \
-e WORDPRESS_DB_NAME=exampledb \
wordpress-deploy:1.0


kubectl -n monitoring  create secret generic wordpress \
--from-literal WORDPRESS_DB_HOST=mysql \
--from-literal WORDPRESS_DB_USER=exampleuser \
--from-literal WORDPRESS_DB_PASSWORD=examplepassword \
--from-literal WORDPRESS_DB_NAME=exampledb

kubectl -n monitoring create secret generic mysql \
--from-literal MYSQL_USER=exampleuser \
--from-literal MYSQL_PASSWORD=examplepassword \
--from-literal MYSQL_DATABASE=exampledb