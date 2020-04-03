#/**
# * Licensed to the Apache Software Foundation (ASF) under one
# * or more contributor license agreements.  See the NOTICE file
# * distributed with this work for additional information
# * regarding copyright ownership.  The ASF licenses this file
# * to you under the Apache License, Version 2.0 (the
# * "License"); you may not use this file except in compliance
# * with the License.  You may obtain a copy of the License at
# *
# *     http://www.apache.org/licenses/LICENSE-2.0
# *
# * Unless required by applicable law or agreed to in writing, software
# * distributed under the License is distributed on an "AS IS" BASIS,
# * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# * See the License for the specific language governing permissions and
# * limitations under the License.
# */
#!/bin/bash

declare -a supported_Elasticsearch_versions=("7.6.1")
declare -A es_lucene_version_m=(["7.6.1"]="8.4.0")

# Repo Address
ES_REPO=https://github.com/elastic/elasticsearch.git
ES_version_base="7.6.1"


ES_version=$1
QATCodec_SRC_DIR=$2

ES_QAT_DIR=$QATCodec_SRC_DIR/es_qat_wrapper/${ES_version_base}/elasticsearch
TARGET_DIR=$QATCodec_SRC_DIR/es_qat_wrapper/${ES_version_base}/target
ES_SRC_DIR=$TARGET_DIR/elasticsearch


function clone_repo(){
  echo "Clone Branch $1 from Repo $2"
  git clone -b $1 --single-branch $2 $ES_SRC_DIR
}

function checkout_branch(){
  pushd $ES_SRC_DIR
  Branch_name=VERSION-${ES_version_base}
  git checkout -b $Branch_name
  popd
}

function usage(){
  printf "Usage: sh build_es_jars.sh es_version [PATH/TO/QAT_Codec_SRC]\n (e.g. sh build_es_jars.sh 7.6.1 /home/user/workspace/QATCodec)\n"
  exit 1
}

function check_ES_version(){
  valid_version=false
  for v in $supported_Elasticsearch_versions
  do
  	if [ "$v" =  "$1" ]; then
		valid_version=true
    		break;
	fi
  done
  if ! $valid_version ; then
  	printf "Unsupported elasticsearch version $1, current supported versions include: ${supported_Elasticsearch_versions[@]} \n"
  	exit 1
  fi
}

apply_patch_to_es(){
  pushd $TARGET_DIR
  ES_TAG="v${ES_version_base}"
  clone_repo $ES_TAG $ES_REPO
  checkout_branch
  echo yes | cp -rf $ES_QAT_DIR/buildSrc/libs $ES_SRC_DIR/buildSrc
  popd
}

apply_diff_to_es(){
   pushd $ES_SRC_DIR
   git apply --reject --whitespace=fix $ES_QAT_DIR/elasticsearch_7_6_1.diff
   popd
}

if [ "$#" -ne 2 ]; then
  usage
fi


check_ES_version $ES_version

if [ -d $TARGET_DIR ]; then
  echo "$TARGET_DIR is not clean"
else
  mkdir -p $TARGET_DIR
fi

apply_patch_to_es
apply_diff_to_es