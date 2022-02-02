env | while IFS= read -r line; do
  name=${line%%=*}
  if( ! echo "$name" | grep -i "_FILE$" > /dev/null ); then
    continue
  fi
  value=${line#*=}
  if [ -z "$value" ]; then
    continue
  fi
  if [ ! -e "$value" ]; then
    continue
  fi
  nameNoFile=$(echo ${name%_FILE*})
  valueNoFile=$(sh -c "echo \$${nameNoFile}")
  if [ ! -z "$valueNoFile" ]; then
    continue
  fi
  valueFile=$(cat "$value")
  if [ -z "$valueFile" ]; then
    continue
  fi
  export "$nameNoFile"="$valueFile"
done
