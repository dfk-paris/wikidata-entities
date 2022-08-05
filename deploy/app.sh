#!/bin/bash -e

if ! which npm > /dev/null ; then
  echo "npm not available, can't continue"
fi

function deploy {
  setup
  deploy_code
  cleanup

  # frontend
  local "npm run build"
  local "bundle exec bin/index"

  remote "mkdir $CURRENT_PATH/public"
  upload "frontend/public/" "$CURRENT_PATH/public/"

  finalize
}

function configure {
  source deploy/config.sh
  $1
  source deploy/lib.sh
}

configure $1
deploy