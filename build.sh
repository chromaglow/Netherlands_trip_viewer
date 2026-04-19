#!/bin/bash
# Inject MAPBOX_TOKEN environment variable into index.html at deploy time
if [ -n "$MAPBOX_TOKEN" ]; then
  sed -i "s|YOUR_MAPBOX_TOKEN_HERE|$MAPBOX_TOKEN|g" index.html
  echo "Mapbox token injected successfully"
else
  echo "WARNING: MAPBOX_TOKEN not set, map will not render"
fi
