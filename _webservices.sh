#!/bin/bash

ws_type=${1}
orig_dir=$(pwd)
cd webservices

# Now deploy all webservices excluding default
for webservice in $(ls -d ${ws_type}_*); do

  work_dir=$(pwd)
  temp_dir=/tmp/${PROJECT}-${webservice}
  source_repo=${webservice//_/-}

  echo "Changing to temporary directory ..."
  mkdir $temp_dir && cd $temp_dir
  echo "Cloning web service repo ${source_repo} ..."
  gcloud source repos clone ${source_repo}

  echo "Copying files from inception repo ..."
  cd ${source_repo}
  shopt -s dotglob # include dotfiles
  cp -a ${work_dir}/${webservice}/* .
  shopt -u dotglob # unset again

  echo "Checking if web service is already running ..."
  gcloud app services list 2>&1 | grep -q ^"${source_repo} "
  if [ $? -ne 0 ]; then
    echo "It isn't."
    echo "Update project in app.yaml ..."
    sed -i'.bck' "s/^    PROJECT:.*/    PROJECT: $PROJECT/g" app.yaml
    rm app.yaml.bck  # sed command has to be portable but then creates unnecessary backup
    echo "Pushing code to deploy web service ..."
    git add .
    git commit -m "Initial commit"
    git push origin master
  else
    echo "Looks good."
  fi

  echo "Moving back to original directory ..."
  cd ${work_dir}
  echo "Deleting temporary directory ..."
  rm -rf ${temp_dir}

done

cd ${orig_dir}
