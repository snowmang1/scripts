# now included in script git
case $1 in
  'run-instance')
    aws-vault exec dev-sandbox -- aws ec2 run-instances --image-id ami-02eac2c0129f6376b --count 1 --instance-type t2.micro --key-name  $2 \
      --security-groups evandrake-bootcamp
    ;;
    # $2 keypair

  'name')
    aws-vault exec $2 -- aws ec2 create-tags --resources $3 --tags "Key=Name,Value=$4"
    ;;
    # $2 enviornment
    # $3 ID
    # $4 my name

  'ssh1')
    ssh -i evandrake-dob-pair.pem centos@ec2-54-210-215-29.compute-1.amazonaws.com
    ;;

  'ssh2')
    ssh -i "evandrake-jenkins-agent.pem" centos@ec2-3-87-194-206.compute-1.amazonaws.com
    ;;

  'stop')
    aws-vault exec $2 -- aws ec2 stop-instances --instance-ids $3
    ;;
    # $2 ex: dev-sandbox
    # $3 ID

  'start')
    aws-vault exec $2 -- aws ec2 start-instances --instance-ids $3
    ;;
    # $2 ex: dev-sandbox
    # $3 ID

  'perm-delete')
    # CAREFULL
    echo CAREFULL MORON YOU ARE DELETING YOUR SERV "$3"
    echo
    echo YOU NOW HAVE 10 SECONDS TO CTRL-C BEFORE IT IS GONE FOREVER
    sleep 10
    aws-vault exec $2 -- $ aws ec2 terminate-instances --instance-ids $3
    echo
    echo ITS GONE NOW
    ;;

esac
