CONFIG=config.yml

if [[ -f $CONFIG ]]; then
  NAME=$( cat $CONFIG | yq '.name' ) ENV=$(  cat $CONFIG | yq '.env'  )
  KEY=$(  cat $CONFIG | yq '.key'  ) GRP=$(  cat $CONFIG | yq '.grp'  )
  AMI=$(  cat $CONFIG | yq '.ami'  ) USR_DATA=$( cat $CONFIG | yq '.user_data'  )
  SSH_USER=$(   cat $CONFIG | yq '.ssh_user'  )
fi

function scp_up {
  scp -i $KEY'.pem' -r './setup' $SSH_USER'@'$1':~'
}

function get_dns {
  DNS=$(aws ec2 describe-instances --instance-ids $1 | yq '.Reservations[0] .Instances[0].NetworkInterfaces[0].Association.PublicDnsName')
}

function file_index {
  if [[ ! -f ./${JSON_FILE[0]} ]]; then
    INDEX=0
  elif [[ ! -f ./${JSON_FILE[1]} ]]; then
    INDEX=1
  else
    echo ERROR: BOTH FILES EXIST
    exit
  fi
}

function setup {
  # check that if gum is installed
  if ! which gum > /dev/null ; then
    echo you need to install gum
    echo try: brew install gum
    exit
  fi
  # this will use gum to create a config file
  NAME=$(gum input --placeholder "name")
  ENV=$(gum input --placeholder "environment")
  KEY=$(gum input --placeholder "key pair minus the '.pem'")
  GRP=$(gum input --placeholder "security group")
  AMI=$(gum input --placeholder "AMI id")
  USR_DATA=$(gum input --placeholder "user data script")
  SSH_USER=$(gum input --placeholder "ssh username")
  echo name:        >>    $CONFIG
  echo "    "$NAME  >>    $CONFIG
  echo env:         >>    $CONFIG
  echo "    "$ENV   >>    $CONFIG
  echo key:         >>    $CONFIG
  echo "    "$KEY   >>    $CONFIG
  echo grp:         >>    $CONFIG
  echo "    "$GRP   >>    $CONFIG
  echo ami:         >>    $CONFIG
  echo "    "$AMI   >>    $CONFIG
  echo user_data:   >>    $CONFIG
  echo "    "$USR_DATA >> $CONFIG
  echo ssh_user:   >>     $CONFIG
  echo "    "$SSH_USER >> $CONFIG
  exit
}

function arg_check {
  local ar_len=${#JSON_FILE[*]}
  if [[ $# < 2 ]]; then
    num=$(gum input --placeholder "input is between 0 and ${ar_len} inclusive")
  fi
  while (( $num < 0 )) || (( $num > ${#JSON_FILE[*]} )) ; do
    num=$(gum input --placeholder "input needs to be between 0 and ${ar_len} inclusive")
  done
}

function pop_ar {
  #populate array of json config files
  ar=$(ls -p | grep -v / | grep '.json')
  JSON_FILE=(`echo $ar`) # seporates ar in an array by spaces or \n
}
function new_ar {
  #creates name for new json conf file
  local num=${#JSON_FILE[*]}
  num=$((num + 1)) # arithmatic
  NEW_FILE="ins${num}.json" #new files differ by number
}

JSON_FILE=()
INDEX=0

if [[ ! -f config.yml ]]; then
  setup
fi

case $1 in
  
  'a'|'assume-role')
    if [[ $# < 2 ]]; then
      num=$(gum input --placeholder 'input must be either 0 or 1')
    else
      num=$2
    fi
    while [[ num == 1 || num == 0 ]]; do
      num=$(gum input --placeholder 'input needs to be either 0 or 1')
    done
    aws-vault exec --duration ${num}h $ENV
    exit
    ;;
    #2 time
  
  'c'|'create-instance')
    file_index  # must run at the begining of every time we dynamically check JSON_FILE
    pop_ar      # must run b/c JSON_FILE will alwase start empty
    new_ar      # has to run to get file name
    aws ec2 run-instances --image-id $AMI --count 1 --instance-type t2.micro --key-name  $KEY \
      --security-groups $GRP --user-data file://$USR_DATA > $NEW_FILE

    if [ $? -ne 0 ]; then #checks if command ran successfully success = 0 therefore if it isn't that remove those empty json files
      rm $NEW_FILE
    fi
    exit
    ;;

  'n'|'name')
    pop_ar
    arg_check $2
    ID=$(cat ${JSON_FILE[$num]} | jq '.Instances[0] .InstanceId' | tr -d '"') && \
    aws ec2 create-tags --resources $ID --tags "Key=Name,Value=$NAME" && \
    get_dns $ID && \
    scp_up $DNS
    exit
    ;;
    # 2 serv #

  'ssh')
    pop_ar
    arg_check $2
    ID=$(cat ${JSON_FILE[$num]} | jq '.Instances[0] .InstanceId' | tr -d '"')
    get_dns $ID
    ssh -i $KEY'.pem' $SSH_USER'@'$DNS
    exit
    ;;
    # 2 serv #
    
  'stop')
    pop_ar
    arg_check $2
    ID=$(cat ${JSON_FILE[$num]} | jq '.Instances[0] .InstanceId' | tr -d '"')
    aws ec2 stop-instances --instance-ids $ID
    exit
    ;;
    # 2 serv #

  'start')
    pop_ar
    arg_check $2
    ID=$(cat ${JSON_FILE[$num]} | jq '.Instances[0] .InstanceId' | tr -d '"')
    aws ec2 start-instances --instance-ids $ID
    exit
    ;;
    # 2 serv #

  'clear-role')
    JOB_STR=$(bash pid-script.sh)
    if [ ! -z ${JOB_STR} ]; then
      gum confirm 'Clear the assumed role?' && kill -9 $JOB_STR # confirm role clearing
    else
      echo "Role does not exist."
    fi
    exit
    ;;

  'd'|'perm-delete')
    pop_ar
    arg_check $2
    ID=$(cat ${JSON_FILE[$num]} | jq '.Instances[0] .InstanceId' | tr -d '"')
    gum confirm 'Delete Instance ${ID}?' && aws ec2 terminate-instances --instance-ids "$ID" && rm ${JSON_FILE[$num]} #confirm deletion
    exit
    ;;
    # 2 serv #

esac

echo a, assume-role [time in hours] 
echo  - NOTE: Max Session 1 hour.
echo
echo c, create-instance [how many?]
echo
echo n, name [serv \#]
echo      - should now also upload \'setup\' dir to serv
echo      - [serv \#] specifies name of json file saved during create-instance
echo
echo ssh [serv /#]
echo
echo start [serv /#]
echo
echo stop [serv /#]
echo
echo clear-role - clears the aws assumed role
echo
echo d, perm-delete [serv \#]
echo
