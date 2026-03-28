#!/bin/bash
# src/docker_image_buid_push.sh
# Builds and pushes all Docker images under src/*/Dockerfile to AWS ECR

set -e

AWS_REGION="ap-northeast-1"
AWS_ACCOUNT_ID="468227866873"
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
TAG=$(git rev-parse --short HEAD 2>/dev/null || date +%s)

echo "🔹 Logging in to Amazon ECR..."
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_URI"

echo "🔹 Searching for Dockerfiles in ./src/"
mapfile -t DOCKERFILES < <(find src -type f -name Dockerfile)

if [ ${#DOCKERFILES[@]} -eq 0 ]; then
  echo "❌ No Dockerfiles found under src/. Expected: src/<service>/Dockerfile"
  exit 1
fi

echo "🔹 Found ${#DOCKERFILES[@]} services."
IMAGES=()

for dockerfile in "${DOCKERFILES[@]}"; do

  service=$(basename "$(dirname "$dockerfile")")
  image="${ECR_URI}/${service}:${TAG}"
  latest="${ECR_URI}/${service}:latest"

  IMAGES+=("$service")

  echo "🔍 Checking if ECR repo exists for ${service}..."

  aws ecr describe-repositories \
  --repository-names "$service" \
  --region "$AWS_REGION" > /dev/null 2>&1 || {

    echo "📦 Creating repository ${service}"
    aws ecr create-repository \
      --repository-name "$service" \
      --region "$AWS_REGION" > /dev/null
  }

  echo "🚀 Building image for ${service}"
  docker build -t "$image" "$(dirname "$dockerfile")"

  docker tag "$image" "$latest"

done


echo "🔹 Pushing all images with tag ${TAG}"

for service in "${IMAGES[@]}"; do
  image="${ECR_URI}/${service}:${TAG}"
  echo "⬆️  Pushing ${image}"
  docker push "$image"
done


echo "🔹 Pushing all :latest tags"

for service in "${IMAGES[@]}"; do
  latest="${ECR_URI}/${service}:latest"
  echo "⬆️  Pushing ${latest}"
  docker push "$latest"
done

echo "🎉 All ${#IMAGES[@]} services pushed successfully to ${ECR_URI}"
echo "Tags pushed: ${TAG} and latest"