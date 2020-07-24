set -e

rm -rf microservices-demo

git clone https://github.com/GoogleCloudPlatform/microservices-demo

cd microservices-demo

HTTPS_PROXY=localhost:8888 kubectl apply -f ./release/kubernetes-manifests.yaml

