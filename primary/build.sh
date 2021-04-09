#!/bin/bash
if [-n $1 ]; then
    version=$1
else
    version='latest'
fi        

docker build -t primary:${version} .