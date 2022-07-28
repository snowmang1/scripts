
yum install -y vim

echo "if [[ -x '\$(command -v vi)' ]]; then
	# Vim9Script release is when this happened...
	# I betrayed vim and now I am on the dark side
	alias vi='nvim'
fi" >> ~/.bashrc

mv .vimrc ~/.vimrc

source ~/.bashrc
