#!/bin/bash

if [ -d target ]; then
    rm -rf target
    mkdir target
fi

zip -q -r target/toaster extra package *.sh
