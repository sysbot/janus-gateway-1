#!/bin/bash

DIST_DIR=`pwd`/.dist

# Clean
rm -rf $DIST_DIR

set -e

# Build
./autogen.sh
./configure --prefix=/opt/janus \
 --disable-data-channels  \
 --disable-docs  \
 --disable-mqtt  \
 --disable-plugin-audiobridge  \
 --disable-plugin-echotest  \
 --disable-plugin-recordplay  \
 --disable-plugin-sip  \
 --disable-plugin-textroom  \
 --disable-plugin-videocall  \
 --disable-plugin-voicemail  \
 --disable-post-processing  \
 --disable-rabbitmq  \
 --disable-turn-rest-api  \
 --disable-websockets \
 --enable-unix-sockets  \
 --enable-plugin-streaming  \
 --enable-plugin-videoroom  \
 --enable-rest  \
 --enable-static  \

# PAS: Not sure what this one is
# --disable-sample-event-handler  \

# Make a distributable file
make check install DESTDIR=$DIST_DIR
cd $DIST_DIR
cp /usr/lib/libsrtp2.so opt/janus/lib
cp /usr/lib/libsrtp2.so.1 opt/janus/lib
tar cvzf ../janus.tgz .

# Push to S3
aws s3 cp --region us-west-2 ../janus.tgz  \
 s3://caffeine-bin/jenkins/janus/janus-$BUILD_NUMBER.tgz
