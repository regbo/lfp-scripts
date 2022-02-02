OUT_FILE=$1
if [ -z "$OUT_FILE" ]; then
  OUT_FILE=./env.list
fi
echo "" > $OUT_FILE
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
  valueFileEscaped=${1@Q}
  echo "$nameNoFile=${valueFileEscaped:2:-1}" >> $OUT_FILE
done
