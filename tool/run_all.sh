#!/usr/bin/env bash

set +xe

export PKG="web_socket_io"
./tool/travis.sh dartfmt dartanalyzer test_vm
export PKG="web_socket"
./tool/travis.sh dartfmt dartanalyzer test_vm
