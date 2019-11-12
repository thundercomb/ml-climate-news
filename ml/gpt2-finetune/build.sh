export CONTAINER_NAME=gpt2-finetune
export TAG_NAME=0.6

docker build -t ${CONTAINER_NAME} .
docker tag ${CONTAINER_NAME} eu.gcr.io/${PROJECT}/${CONTAINER_NAME}:${TAG_NAME}
docker push eu.gcr.io/${PROJECT}/${CONTAINER_NAME}:${TAG_NAME}
