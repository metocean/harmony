#!/bin/sh
set -e

# Install harmony
cp -R /install/harmony/* /
npm i -g redwire-harmony

# Clean up
rm -rf /install