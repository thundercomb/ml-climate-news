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

cd ..
