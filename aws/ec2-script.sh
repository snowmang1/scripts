
AWS_KEY=evandrake-dob-pair.pem

function scp_up {
  scp -i $AWS_KEY -r 'setup' $SSH_LOC:~
}

function get_dns () {
  DNS=$( aws-vault exec $1 -- aws ec2 describe-instances --instance-ids $2 | yq '.Reservations[0] .Instances[0].NetworkInterfaces[0].Association.PublicDnsName' )
}

# now included in script git
case $1 in
  'run-instance')
    aws-vault exec dev-sandbox -- aws ec2 run-instances --image-id ami-02eac2c0129f6376b --count 1 --instance-type t2.micro --key-name  $2 \
      --security-groups evandrake-bootcamp > ins.json
    exit
    ;;
    # $2 keypair

  'name')
    ID=$(cat ins.json | jq '.Instances[0] .InstanceId' | tr -d '"')
    aws-vault exec $2 -- aws ec2 create-tags --resources $ID --tags "Key=Name,Value=$3"
    scp_up
    exit
    ;;
    # $2 enviornment
    # $3 my name

  'ssh')
    ID=$(cat ins.json | jq '.Instances[0] .InstanceId' | tr -d '"')
    get_dns $2 $ID
    echo $DNS
    ssh -i $AWS_KEY 'centos@'${DNS}
    exit
    ;;

  'stop')
    ID=$(cat ins.json | jq '.Instances[0] .InstanceId' | tr -d '"')
    aws-vault exec $2 -- aws ec2 stop-instances --instance-ids $ID
    exit
    ;;
    # $2 ex: dev-sandbox
    # $3 ID

  'start')
    ID=$(cat ins.json | jq '.Instances[0] .InstanceId' | tr -d '"')
    aws-vault exec $2 -- aws ec2 start-instances --instance-ids $ID
    exit
    ;;
    # $2 ex: dev-sandbox
    # $3 ID

  'perm-delete')
    # CAREFULL
    ID=$(cat ins.json | jq '.Instances[0] .InstanceId' | tr -d '"')
    echo CAREFULL MORON YOU ARE DELETING YOUR SERV "$ID"
    echo
    echo YOU NOW HAVE 10 SECONDS TO CTRL-C BEFORE IT IS GONE FOREVER
    sleep 10
    aws-vault exec "$2" -- aws ec2 terminate-instances --instance-ids "$ID"
    echo
    echo ITS GONE NOW
    exit
    ;;
    # $2 dev environment
    # $3 ID

esac

echo
echo run-instance [keyname]
echo
echo name [enviornment] [your name]
echo      - should now also upload \'setup\' dir to serv
echo
echo "ssh[1|2] <- configure to your instance"
echo
echo "stop <- [enviornment]"
echo
echo perm-delete [enviornment]
echo
