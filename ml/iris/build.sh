export CONTAINER_NAME=iris
export TAG_NAME=0.3

docker build -t ${CONTAINER_NAME} .
docker tag ${CONTAINER_NAME} eu.gcr.io/${PROJECT}/${CONTAINER_NAME}:${TAG_NAME}
docker push eu.gcr.io/${PROJECT}/${CONTAINER_NAME}:${TAG_NAME}
