#!/bin/sh
cd "$(dirname "$0")" && exec node build.mjs "$@"
