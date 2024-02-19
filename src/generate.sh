#!/bin/bash
set -e

THIS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

swiftc -c "$THIS_DIR/../ios/Classes/web_kit_wrapper.swift"  \
    -module-name web_kit_plugin                               \
    -emit-objc-header-path "$THIS_DIR/web_kit_wrapper.h"

dart run ffigen --config="$THIS_DIR/ffigen.yaml"
