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

ROOT_DIR=$(mktemp -d)
DEPS_DIR=$ROOT_DIR/deps
BUILD_DIR=$ROOT_DIR/app
INDEX_DIR=$DEPS_DIR/0
MICROGATEWAY_DIR=$INDEX_DIR/microgateway

bin_dir=$(pwd)/../bin
util_dir=$bin_dir/util
lib_dir=$(pwd)/../lib
custom_plugins=$(pwd)/resources/plugins

setup() {
    echo "Setting up tests..."
    mkdir -p $INDEX_DIR && mkdir -p $BUILD_DIR && mkdir -p $MICROGATEWAY_DIR
    cp -r $bin_dir $ROOT_DIR/bin && cp -r $lib_dir $ROOT_DIR/lib
    cd $ROOT_DIR/bin/util
}

cleanup() {
    echo "Removing temp dir"
    rm -rf $ROOT_DIR
}

cleanup_mg() {
    rm -rf $INDEX_DIR/microgateway/.*
    rm -rf $INDEX_DIR/microgateway/*
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
        cleanup_mg
        printf "SUCCESS\n\n------------------------------\n\n"
    fi
}

test_microgateway_install_default() {
    echo "Testing default values"
    ./microgateway_install $ROOT_DIR $BUILD_DIR $MICROGATEWAY_DIR
    error_check 0 $? "Expected default setup to not fail"
}

test_microgateway_install_custom() {
    echo "Testing valid custom version with \"v\""
    export APIGEE_MICROGATEWAY_VERSION="v2.5.10"
    ./microgateway_install $ROOT_DIR $BUILD_DIR $MICROGATEWAY_DIR
    error_check 0 $? "Expected $APIGEE_MICROGATEWAY_VERSION setup to not fail"

    echo "Testing valid custom version without \"v\""
    export APIGEE_MICROGATEWAY_VERSION="2.5.10"
    ./microgateway_install $ROOT_DIR $BUILD_DIR $MICROGATEWAY_DIR
    error_check 0 $? "Expected $APIGEE_MICROGATEWAY_VERSION setup to not fail"

    echo "Testing invalid custom version"
    export APIGEE_MICROGATEWAY_VERSION="v10.5.10"
    ./microgateway_install $ROOT_DIR $BUILD_DIR $MICROGATEWAY_DIR
    error_check 1 $? "Expected $APIGEE_MICROGATEWAY_VERSION setup to fail"

    unset APIGEE_MICROGATEWAY_VERSION
}

test_microgateway_install_local() {
    (cd $ROOT_DIR/lib && git clone https://github.com/apigee-internal/microgateway.git)
    echo "Testing non-preinstalled local version"
    ./microgateway_install $ROOT_DIR $BUILD_DIR $MICROGATEWAY_DIR
    error_check 0 $? "Expected non-preinstalled local version to not fail"

    echo "Testing preinstalled local version"
    npm install --prefix $ROOT_DIR/lib/microgateway #install dependencies before trying install
    ./microgateway_install $ROOT_DIR $BUILD_DIR $MICROGATEWAY_DIR
    error_check 0 $? "Expected pre-installed local version to not fail"

    rm -rf $ROOT_DIR/lib/microgateway
}

test_microgateway_install_custom_plugins() {
    echo "Testing non-preinstalled custom plugins"
    cp -r $custom_plugins $BUILD_DIR
    export APIGEE_MICROGATEWAY_CUST_PLUGINS=plugins
    ./microgateway_install $ROOT_DIR $BUILD_DIR $MICROGATEWAY_DIR
    error_check 0 $? "Expected non-preinstalled custom plugins to not fail"

    echo "Testing preinstalled plugins"
    ./microgateway_install $ROOT_DIR $BUILD_DIR $MICROGATEWAY_DIR
    error_check 0 $? "Expected pre-installed custom plugins to not fail"

    unset $APIGEE_MICROGATEWAY_CUST_PLUGINS
}

setup
test_microgateway_install_default
test_microgateway_install_custom
test_microgateway_install_local
test_microgateway_install_custom_plugins
cleanup