
AWS_KEY=evandrake-dob-pair.pem
CONFIG=config.yml

if [[ -f $CONFIG ]]; then
  NAME=$( cat $CONFIG | yq '.name' )
  ENV=$(  cat $CONFIG | yq '.env'  )
  KEY=$(  cat $CONFIG | yq '.key'  )
fi

function scp_up {
  scp -i $AWS_KEY -r './setup' 'centos@'$1':~'
}

function get_dns {
  DNS=$( aws-vault exec $1 -- aws ec2 describe-instances --instance-ids $2 | yq '.Reservations[0] .Instances[0].NetworkInterfaces[0].Association.PublicDnsName' )
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
  ENV=$(gum input --placeholder "enviornment")
  KEY=$(gum input --placeholder "key pair minus the '.pem'")
  echo name:        >>    $CONFIG
  echo "    "$NAME  >>    $CONFIG
  echo env:         >>    $CONFIG
  echo "    "$ENV   >>    $CONFIG
  echo key:         >>    $CONFIG
  echo "    "$KEY   >>    $CONFIG
  exit
}

JSON_FILE=('ins.json' 'ins2.json')
INDEX=0

if [[ ! -f config.yml ]]; then
  setup
fi

case $1 in
  'c'|'create-instance')
    file_index  # must run at the begining of every time we dynamically check JSON_FILE
    aws-vault exec $ENV -- aws ec2 run-instances --image-id ami-02eac2c0129f6376b --count 1 --instance-type t2.micro --key-name  $KEY_PAIR \
      --security-groups evandrake-bootcamp --user-data file://user-script.sh > ${JSON_FILE[$INDEX]}
    exit
    ;;

  'n'|'name')
    ID=$(cat ./${JSON_FILE[$2]} | jq '.Instances[0] .InstanceId' | tr -d '"') &&
    aws-vault exec $ENV -- aws ec2 create-tags --resources ${ID} --tags "Key=Name,Value=$NAME"
    get_dns $ENV $ID
    scp_up $DNS
    exit
    ;;
    # 2 serv #

  'ssh')
    ID=$(cat ${JSON_FILE[$2]} | jq '.Instances[0] .InstanceId' | tr -d '"')
    get_dns $ENV $ID
    echo $DNS
    ssh -i $AWS_KEY 'centos@'$DNS
    exit
    ;;
    # 2 serv #
    
  'stop')
    ID=$(cat ${JSON_FILE[$2]} | jq '.Instances[0] .InstanceId' | tr -d '"')
    aws-vault exec $ENV -- aws ec2 stop-instances --instance-ids $ID
    exit
    ;;
    # 2 serv #

  'start')
    ID=$(cat ${JSON_FILE[$2]} | jq '.Instances[0] .InstanceId' | tr -d '"')
    aws-vault exec $DEV -- aws ec2 start-instances --instance-ids $ID
    exit
    ;;
    # 2 serv #

  'perm-delete')
    # CAREFULL
    ID=$(cat ${JSON_FILE[$2]} | jq '.Instances[0] .InstanceId' | tr -d '"')
    echo CAREFULL MORON YOU ARE DELETING YOUR SERV "$ID"
    echo
    echo YOU NOW HAVE 10 SECONDS TO CTRL-C BEFORE IT IS GONE FOREVER
    sleep 10
    aws-vault exec $DEV -- aws ec2 terminate-instances --instance-ids "$ID"
    rm ${JSON_FILE[$2]}
    echo
    echo ITS GONE NOW
    exit
    ;;
    # 2 serv #

esac

echo
echo create-instance [how many?]
echo
echo name [serv \#]
echo      - should now also upload \'setup\' dir to serv
echo      - [serv \#] specifies name of json file saved during create-instance
echo
echo ssh [serv /#]
echo
echo start [serv /#]
echo
echo stop [serv /#]
echo
echo perm-delete [serv \#]
echo
