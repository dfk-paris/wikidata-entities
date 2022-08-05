#!/bin/bash

export REPO="."
export HOST="app@192.168.30.213"
export SSH_KEY="$HOME/.ssh/id_rsa"
export PORT="22"
export RUBY_VERSION="3.0.4"
export KEEP=5

function ng {
  export DEPLOY_TO="/var/storage/host/dfkv-ng"
  export COMMIT="ng"
  export APP_ENV="ng"
}

function production {
  export DEPLOY_TO="/var/storage/host/dfkv"
  export COMMIT="master"
  export APP_ENV="production"
}
