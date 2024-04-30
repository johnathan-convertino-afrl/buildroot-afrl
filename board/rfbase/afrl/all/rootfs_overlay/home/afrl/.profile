: "${USER=$(id -un)}" "${HOSTNAME=$(uname -n)}"
if [ $0 = "-sh" ]; then
  export PS1='$USER@$HOSTNAME:$PWD\$ '
fi
