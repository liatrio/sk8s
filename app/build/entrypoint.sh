#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o xtrace

exec /usr/local/bin/gunicorn  \
  --chdir /app                \
  --bind 0.0.0.0:80           \
  --workers 3                 \
  wsgi:app
