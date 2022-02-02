env | while IFS= read -r line; do
  name=${line%%=*}
  if [[ "$name" != *_FILE ]]; then
    continue
  fi
  value=${line#*=}
  if [[ -z "$value" ]]; then
    continue
  fi
  nameNoFile=$(echo ${name%_FILE*})
  valueNoFile="${!nameNoFile}"
  if [[ ! -z "$valueNoFile" ]]; then
    continue
  fi
  valueFile=$(cat "$value")
  if [[ -z "$valueFile" ]]; then
    continue
  fi
  export "$nameNoFile"="$valueFile"
done
