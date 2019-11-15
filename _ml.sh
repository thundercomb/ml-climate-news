#!/bin/bash

cd ml

echo "Creating scripts from templates ..."
for dir in $(ls); do
  cd ${dir}
  for template in $(ls *.py.tmpl); do
    template_type=$(echo ${template} | cut -d'.' -f1)
    echo "Creating ml/${dir}/${template_type}.py ..."
    sed -e "s/\$ML_MODELS_BUCKET/$ML_MODELS_BUCKET/g" \
        -e "s/\$PROJECT/$PROJECT/g" ${template} > ${template_type}.py
  done
  cd ..
done

echo "Commit and push ml code ..."
for dir in $(ls); do
  cd ${dir}

  work_dir=$(pwd)
  temp_dir=/tmp/${PROJECT}-${dir}
  source_repo=${dir}

  echo "Changing to temporary directory ..."
  mkdir $temp_dir && cd $temp_dir
  echo "Cloning web service repo ..."
  gcloud source repos clone ${source_repo}

  echo "Copying files from inception repo ..."
  cd ${source_repo}
  shopt -s dotglob # include dotfiles
  cp -a ${work_dir}/* .
  shopt -u dotglob # unset again

  echo "Pushing code to deploy web service ..."
  git add .
  git commit -m "Initial commit"
  git push origin master

  echo "Moving back to original directory ..."
  cd ${work_dir}
  echo "Deleting temporary directory ..."
  rm -rf ${temp_dir}

  cd ..
done

cd ..
