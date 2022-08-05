CONFIG=config.yml

if [[ -f $CONFIG ]]; then
  NAME=$( cat $CONFIG | yq '.name' ) ENV=$(  cat $CONFIG | yq '.env'  )
  KEY=$(  cat $CONFIG | yq '.key'  )
fi

function scp_up {
  scp -i $KEY'.pem' -r './setup' 'centos@'$1':~'
}
function get_dns {
  DNS=$(aws ec2 describe-instances --instance-ids $1 | yq '.Reservations[0] .Instances[0].NetworkInterfaces[0].Association.PublicDnsName' )
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
  echo name:        >>    $CONFIG
  echo "    "$NAME  >>    $CONFIG
  echo env:         >>    $CONFIG
  echo "    "$ENV   >>    $CONFIG
  echo key:         >>    $CONFIG
  echo "    "$KEY   >>    $CONFIG
  exit
}

function arg_check {
  if [[ $# < 2 ]]; then
    num=$(gum input --placeholder 'choose <0> or <1>')
  fi
  while [[ $num != 0 && $num != 1 ]]; do
    num=$(gum input --placeholder 'must choose either <0> or <1> as input')
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
    arg_check $2
    aws-vault exec --duration ${num}h $ENV
    exit
    ;;
    #2 time
  
  'c'|'create-instance')
    file_index  # must run at the begining of every time we dynamically check JSON_FILE
    pop_ar      # must run b/c JSON_FILE will alwase start empty
    new_ar      # has to run to get file name
    aws ec2 run-instances --image-id ami-02eac2c0129f6376b --count 1 --instance-type t2.micro --key-name  $KEY \
      --security-groups evandrake-bootcamp --user-data file://user-script.sh > $NEW_FILE
    if [ $? -ne 0 ]; then #checks if command ran successfully success = 0 therefore if it isn't that remove those empty json files
      rm $NEW_FILE
    fi
    exit
    ;;

  'n'|'name')
    arg_check $2
    ID=$(cat ./${JSON_FILE[$num]} | jq '.Instances[0] .InstanceId' | tr -d '"') &&
    aws ec2 create-tags --resources $ID --tags "Key=Name,Value=$NAME"
    get_dns $ID
    scp_up $DNS
    exit
    ;;
    # 2 serv #

  'ssh')
    arg_check $2
    ID=$(cat ${JSON_FILE[$num]} | jq '.Instances[0] .InstanceId' | tr -d '"')
    get_dns $ID
    echo $DNS
    ssh -i $AWS_KEY 'centos@'$DNS
    exit
    ;;
    # 2 serv #
    
  'stop')
    arg_check $2
    ID=$(cat ${JSON_FILE[$num]} | jq '.Instances[0] .InstanceId' | tr -d '"')
    aws ec2 stop-instances --instance-ids $ID
    exit
    ;;
    # 2 serv #

  'start')
    arg_check $2
    ID=$(cat ${JSON_FILE[$num]} | jq '.Instances[0] .InstanceId' | tr -d '"')
    aws ec2 start-instances --instance-ids $ID
    exit
    ;;
    # 2 serv #

  'd'|'perm-delete')
    arg_check $2
    ID=$(cat ${JSON_FILE[$num]} | jq '.Instances[0] .InstanceId' | tr -d '"')
    gum confirm 'Delete Instance ${ID}?' && aws ec2 terminate-instances --instance-ids "$ID" # confirm deletion
    rm ${JSON_FILE[$num]}
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
echo d, perm-delete [serv \#]
echo
