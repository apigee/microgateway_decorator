#!/bin/bash

# Copyright 2018 Google LLC

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     https://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

export ROOT_DIR=$(mktemp -d)
export DEPS_DIR=$ROOT_DIR/deps
export BUILD_DIR=$ROOT_DIR/app
export INDEX_DIR=$DEPS_DIR/0
export NODE_DIR=$INDEX_DIR/node

bin_dir=$(pwd)/../bin
util_dir=$bin_dir/util
lib_dir=$(pwd)/../lib

setup() {
    echo "Setting up tests..."
    mkdir -p $INDEX_DIR && mkdir -p $BUILD_DIR && mkdir -p $NODE_DIR
    cp -r $bin_dir $ROOT_DIR/bin && cp -r $lib_dir $ROOT_DIR/lib
    cd $ROOT_DIR/bin/util
}

cleanup() {
    echo "Removing temp dir"
    rm -rf $ROOT_DIR
}

cleanup_node() {
    rm -rf $NODE_DIR/.*
    rm -rf $NODE_DIR/*
}

error_check() {
    expected_code=$1
    actual_code=$2
    error_message=$3
    if [ $actual_code -ne $expected_code ]; then
        echo "FAIL: $error_message"
        cleanup
        exit 1
    else
        cleanup_node
        printf "SUCCESS\n\n------------------------------\n\n"
    fi
}

test_default_install() {
    echo "Testing default values"
    ./node_install $ROOT_DIR $NODE_DIR
    error_check 0 $? "Expected default setup to not fail but got exit status $?"
}

test_custom_install() {
    echo "Testing custom APIGEE_MICROGATEWAY_NODEJS_URL"
    export APIGEE_MICROGATEWAY_NODEJS_URL="https://nodejs.org/dist/v8.11.2/node-v8.11.2-linux-x64.tar.gz"
    ./node_install $ROOT_DIR $NODE_DIR
    error_check 0 $? "Expected custom url to not fail but got exit status $?"

    echo "Testing invalid custom APIGEE_MICROGATEWAY_NODEJS_URL"
    export APIGEE_MICROGATEWAY_NODEJS_URL="https://nodejs.org/dist/v8.11.3/node-v6.11.2-linux-x64.tar.gz"
    ./node_install $ROOT_DIR $NODE_DIR
    error_check 8 $? "Expected invalid custom url to fail with exit status 8 and not $?"
    unset APIGEE_MICROGATEWAY_NODEJS_URL

    echo "Testing custom APIGEE_MICROGATEWAY_NODEJS_VERSION"
    export APIGEE_MICROGATEWAY_NODEJS_VERSION="8.11.2"
    ./node_install $ROOT_DIR $NODE_DIR
    error_check 0 $? "Expected custom version to not fail but got exit status $?"

    echo "Testing invalid custom APIGEE_MICROGATEWAY_NODEJS_VERSION"
    export APIGEE_MICROGATEWAY_NODEJS_VERSION="8.11"
    ./node_install $ROOT_DIR $NODE_DIR
    error_check 8 $? "Expected invalid custom version to fail with exit status 8 and not $?"
    unset APIGEE_MICROGATEWAY_NODEJS_VERSION
}

test_local_install() {
    echo "Testing local install"
    export APIGEE_MICROGATEWAY_NODEJS_FILENAME="node-v8.11.3-linux-x64.tar.gz"
    (cd $ROOT_DIR/lib && wget https://nodejs.org/dist/v8.11.3/node-v8.11.3-linux-x64.tar.gz)
    ./node_install $ROOT_DIR $NODE_DIR
    error_check 0 $? "Expected local install to not fail but got exit status $?"
    unset APIGEE_MICROGATEWAY_NODEJS_FILENAME

    echo "Testing invalid file format"
    touch $ROOT_DIR/lib/node.zip
    export APIGEE_MICROGATEWAY_NODEJS_FILENAME="node.zip"
    ./node_install $ROOT_DIR $NODE_DIR
    error_check 1 $? "Expected invalid format to fail with exit status 1 and not $?"
    unset APIGEE_MICROGATEWAY_NODEJS_FILENAME

    echo "Testing no node file"
    export APIGEE_MICROGATEWAY_NODEJS_FILENAME="doesntexit.tar.gz"
    ./node_install $ROOT_DIR $NODE_DIR
    error_check 1 $? "Expected no file to fail with exit status 1 and not $?"
    unset APIGEE_MICROGATEWAY_NODEJS_FILENAME

    echo "Testing specify both version and file"
    export APIGEE_MICROGATEWAY_NODEJS_FILENAME="node-v8.11.3-linux-x64.tar.gz"
    export APIGEE_MICROGATEWAY_NODEJS_VERSION="8.11.3"
    ./node_install $ROOT_DIR $NODE_DIR
    error_check 1 $? "Expected specifying both version and file to fail with exit status 1 and not $?"
    unset APIGEE_MICROGATEWAY_NODEJS_FILENAME
    unset APIGEE_MICROGATEWAY_NODEJS_VERSION

     echo "Testing specify both version and file"
    export APIGEE_MICROGATEWAY_NODEJS_FILENAME="node-v8.11.3-linux-x64.tar.gz"
    export APIGEE_MICROGATEWAY_NODEJS_URL="https://nodejs.org/dist/v8.11.2/node-v8.11.2-linux-x64.tar.gz"
    ./node_install $ROOT_DIR $NODE_DIR
    error_check 1 $? "Expected specifying both file and url to fail with exit status 1 and not $?"
    unset APIGEE_MICROGATEWAY_NODEJS_FILENAME
    unset APIGEE_MICROGATEWAY_NODEJS_URL
}

setup
test_default_install
test_custom_install
test_local_install
cleanup