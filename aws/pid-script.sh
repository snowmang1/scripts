str=$(ps | grep 'sh ./ec2-script.sh a' | grep -v 'grep')

IFS=' '
read -ra splitIFS<<< "$str"
echo $splitIFS
echo $str
IFS=''
