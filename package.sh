#!/bin/bash

if [ -z target ]; then
    rm -rf target
fi

mkdir target

zip -q -r target/toaster extra package *.sh
