#!/usr/bin/env bash

BUCKET=s3://plazaaaaa.com

cd src
echo "publishing src"
aws s3 cp index.html $BUCKET --profile plaza
aws s3 cp css/ $BUCKET/css/ --recursive --profile plaza
aws s3 cp fonts/ $BUCKET/fonts/ --recursive --profile plaza

echo "invalidating cache"
aws cloudfront create-invalidation --distribution-id ERJB446I96B2L --paths "/*" --profile plaza
