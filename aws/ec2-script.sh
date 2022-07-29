
AWS_KEY=evandrake-dob-pair.pem

function scp_up {
  scp -i $AWS_KEY -r 'setup' $1
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

JSON_FILE=('ins.json' 'ins2.json')
INDEX=0

# now included in script git
case $1 in
  'create-instance')
    file_index  # must run at the begining of every time we dynamically check JSON_FILE
    aws-vault exec dev-sandbox -- aws ec2 run-instances --image-id ami-02eac2c0129f6376b --count 1 --instance-type t2.micro --key-name  $2 \
      --security-groups evandrake-bootcamp --user-data file://user-script.sh > ${JSON_FILE[$INDEX]}
    exit
    ;;
    # $2 keypair
    # 3 how many?

  'name')
    ID=$(cat ./${JSON_FILE[$4]} | jq '.Instances[0] .InstanceId' | tr -d '"')
    aws-vault exec $2 -- aws ec2 create-tags --resources $ID --tags "Key=Name,Value=$3"
    get_dns $4 $ID
    scp_up $DNS
    exit
    ;;
    # $2 enviornment
    # $3 my name
    # serv #

  'ssh')
    ID=$(cat ${JSON_FILE[$3]} | jq '.Instances[0] .InstanceId' | tr -d '"')
    get_dns $2 $ID
    echo $DNS
    ssh -i $AWS_KEY 'centos@'${DNS}
    exit
    ;;
    # enviornment
    # serv #
    
  'stop')
    ID=$(cat ${ JSON_FILE[$4] } | jq '.Instances[0] .InstanceId' | tr -d '"')
    aws-vault exec $2 -- aws ec2 stop-instances --instance-ids $ID
    exit
    ;;
    # $2 ex: dev-sandbox
    # $3 ID
    # serv #

  'start')
    ID=$(cat ${ JSON_FILE[$4] } | jq '.Instances[0] .InstanceId' | tr -d '"')
    aws-vault exec $2 -- aws ec2 start-instances --instance-ids $ID
    exit
    ;;
    # $2 ex: dev-sandbox
    # $3 ID
    # serv #

  'perm-delete')
    # CAREFULL
    ID=$(cat ${JSON_FILE[$3]} | jq '.Instances[0] .InstanceId' | tr -d '"')
    echo CAREFULL MORON YOU ARE DELETING YOUR SERV "$ID"
    echo
    echo YOU NOW HAVE 10 SECONDS TO CTRL-C BEFORE IT IS GONE FOREVER
    sleep 10
    aws-vault exec "$2" -- aws ec2 terminate-instances --instance-ids "$ID"
    rm ${JSON_FILE[$3]}
    echo
    echo ITS GONE NOW
    exit
    ;;
    # $2 dev environment
    # 4 serv #

esac

echo
echo create-instance [key pair name] [how many?]
echo
echo name [enviornment] [your name] [serv \#]
echo      - should now also upload \'setup\' dir to serv
echo
echo "ssh[1|2] [serv #]<- configure to your instance"
echo
echo "stop <- [environment] [serv #]"
echo
echo perm-delete [environment] [serv \#]
echo
