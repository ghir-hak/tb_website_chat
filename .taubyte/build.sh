#!/bin/bash

# Install dependencies
yarn install

# Build the Vue application
yarn build

# Move built files to output directory
if [ -d "dist" ]; then
  cp -r dist/* /out/
  echo "Build completed successfully"
else
  echo "Build failed - dist directory not found"
  exit 1
fi