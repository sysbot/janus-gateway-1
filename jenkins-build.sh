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


# Slack Incoming Webhook for #releases-shepard
SLACK_URL="https://hooks.slack.com/services/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"

# Calculate tags for the image
now=`date "+%Y%m%d-%H%M%S"`
sha=`git rev-parse --short HEAD`
tag="${now}-${sha}"
author=`git show --format="%an <%ae>" | head -1`
change=`git show --format="%s" | head -1`
issue_name=`git show --format="%b" | head -1`

if [[ "$BRANCH_NAME" == "master" || "$BRANCH_NAME" == "v0.2.4-caffeine" ]]; then
  name="janus-${BRANCH_NAME}-${tag}-b${BUILD_ID}"
  color="#23ae4b"
  message="A <$RUN_DISPLAY_URL|Jenkins build> for Janus <https://github.com/caffeinetv/janus|${BRANCH_NAME}> uploaded artifacts to S3"
  fields=$(cat <<EOF
  ,
  {
    "title": "Change",
    "value": "$change\n$issue_name"
  }
EOF
)
else
  name="janus-pr${CHANGE_ID}-${tag}-b${BUILD_ID}"
  color="#00afd0"
  message="A <$RUN_DISPLAY_URL|Jenkins build> for Janus <$CHANGE_URL|$BRANCH_NAME> uploaded artifacts to S3"
fi

zip=${name}.tgz

# Push to S3
echo "Uploading $zip to S3"
aws s3 cp --region us-west-2 ../janus.tgz s3://caffeine-bin/jenkins/janus/$zip

# append to the message the sha256sum and source
appendToMessage = "Update salt to:"
appendToMessage = "${appendToMessage}\n- source: s3://caffeine-bin/jenkins/janus/$zip"
appendToMessage = "${appendToMessage}\n- source_hash: sha256=$(sha256sum $zip|cut -f1 -d' ')"
echo appendToMessage
$message = "${message}\n${appendToMessage}"


PAYLOAD_FILE=`mktemp -t janus-payload.XXXXXXXX`
cat > $PAYLOAD_FILE <<EOF
{
  "attachments":[
    {
      "color": "$color",
      "fallback": "${message}",
      "text": "${message}",
      "mrkdwn_in": ["text", "fields"],
      "fields": [
        {
          "title": "Filename",
          "value": "$zip"
        }
        $fields
      ]
    }
  ]
}
EOF

echo "Posting Slack message..."
curl -X POST --data @${PAYLOAD_FILE} $SLACK_URL
rm ${PAYLOAD_FILE}

echo "DONE"
