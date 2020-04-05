FROM codercom/code-server:latest
RUN sudo apt-get update && sudo apt-get install -y ruby
RUN sudo apt-get install -y nodejs postgresql-client
RUN sudo apt-get install -y gnupg tree jq
RUN sudo apt-get upgrade -y

# Install zsh
RUN sudo apt-get install -y zsh powerline fonts-powerline vim
RUN git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
RUN cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

# Install bat command-line utility
RUN sudo wget https://github.com/sharkdp/bat/releases/download/v0.12.1/bat-musl_0.12.1_amd64.deb && sudo dpkg -i bat-musl_0.12.1_amd64.deb

# Install zsh-autosuggestions command-line utility
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
RUN echo "plugins=(zsh-autosuggestions) \nsource ~/.oh-my-zsh/oh-my-zsh.sh \n" >> ~/.zshrc

# Install hstr command-line utility
SHELL ["/bin/zsh", "-c"]
RUN sudo sh -c "echo \"deb https://www.mindforger.com/debian stretch main \n\" >> /etc/apt/sources.list"
RUN sudo sh -c "wget -qO - https://www.mindforger.com/gpgpubkey.txt | apt-key add -"
RUN sudo apt-get update -qq
RUN sudo apt-get install -y hstr
RUN hstr --show-zsh-configuration >> ~/.hstr
RUN cat ~/.hstr >> ~/.zshrc