#!/bin/bash

PS3="
Please type the number corresponding to your selection and then press the Enter/Return key.
Your choice: "

target=$1

function get_github_username(){
    echo
    echo "Please provide your username for Github."
    echo "** This is required for Augur to clone Github repos ***"
    read -p "GitHub username: " github_username
    echo
}


function get_github_api_key(){
    echo
    echo "Please provide a valid GitHub API key."
    echo "For more information on how to create the key, visit:"
    echo "https://oss-augur.readthedocs.io/en/dev/getting-started/installation.html#backend"
    echo "** This is required for Augur to gather data ***"
    read -p "GitHub API Key: " github_api_key
    echo
}

function get_gitlab_username(){
    echo
    echo "Please provide your username for GitLab."
    echo "** This is required for Augur to clone GitLab repos ***"
    read -p "GitLab username: " gitlab_username
    echo
}

function get_gitlab_api_key(){
    echo
    echo "Please provide a valid GitLab API key."
    echo "For more information on how to create the key, visit:"
    echo "https://oss-augur.readthedocs.io/en/dev/getting-started/installation.html#backend"
    echo "** This is required for Augur to gather data ***"
    read -p "GitLab API Key: " gitlab_api_key
    echo
}

function get_facade_repo_path() {

  echo "The Facade data collection worker will clone repositories to this machine to run its analysis."
  echo "Please select a new or existing directory for the Facade worker to use:"
  echo

  while true; do
    read -e -p "Facade worker directory: " facade_repo_directory
    facade_repo_directory=$(realpath $facade_repo_directory)
    echo

    if [[ -d "$facade_repo_directory" ]]; then
      read -r -p "That directory already exists. Use it? [Y/n]: " facade_response
      case "$facade_response" in
          [nN][oO]|[nN]) 
              continue
              ;;
          *)
              break
              ;;
      esac
    else
      read -r -p "That directory does not exist. Create it? [Y/n]: " facade_response
      case "$facade_response" in
          [nN][oO]|[nN]) 
              continue
              ;;
          *)
              mkdir "$facade_repo_directory"
              echo "Directory created."
              break
              ;;
      esac
    fi
  done

  [[ "${facade_repo_directory}" != */ ]] && facade_repo_directory="${facade_repo_directory}/"
}

function get_rabbitmq_broker_url(){
    echo
    echo "Please provide your rabbitmq broker url."
    echo "** This is required for Augur to run all collection tasks. ***"
    read -p "broker_url: " rabbitmq_conn_string
    echo
}


function create_config(){

    if [[ -z "${AUGUR_GITHUB_API_KEY}" ]]
    then
        get_github_api_key
    else
    echo
    echo "Found AUGUR_GITHUB_API_KEY environment variable with value $AUGUR_GITHUB_API_KEY"
    echo "Using it in the config" 
    echo "Please unset AUGUR_GITHUB_API_KEY if you would like to be prompted for a github api key"
      github_api_key=$AUGUR_GITHUB_API_KEY
    echo
    fi

    if [[ -z "${AUGUR_GITHUB_USERNAME}" ]]
    then
        get_github_username
    else
    echo
    echo "Found AUGUR_GITHUB_USERNAME environment variable with value $AUGUR_GITHUB_USERNAME"
    echo "Using it in the config" 
    echo "Please unset AUGUR_GITHUB_USERNAME if you would like to be prompted for a github username"
      github_username=$AUGUR_GITHUB_USERNAME
    echo
    fi

    if [[ -z "${AUGUR_GITLAB_API_KEY}" ]]
    then
        get_gitlab_api_key
    else
    echo
    echo "Found AUGUR_GITLAB_API_KEY environment variable with value $AUGUR_GITLAB_API_KEY"
    echo "Using it in the config" 
    echo "Please unset AUGUR_GITLAB_API_KEY if you would like to be prompted for a gitlab api key"
      gitlab_api_key=$AUGUR_GITLAB_API_KEY
    echo
    fi


    if [[ -z "${AUGUR_GITLAB_USERNAME}" ]]
    then
        get_gitlab_username
    else
    echo
    echo "Found AUGUR_GITLAB_USERNAME environment variable with value $AUGUR_GITLAB_USERNAME"
    echo "Using it in the config" 
    echo "Please unset AUGUR_GITLAB_USERNAME if you would like to be prompted for a gitlab username"
      gitlab_username=$AUGUR_GITLAB_USERNAME
    echo
    fi

    if [[ -z "${AUGUR_FACADE_REPO_DIRECTORY}" ]]
    then
        get_facade_repo_path
    else
    echo
    echo "Found AUGUR_FACADE_REPO_DIRECTORY environment variable with value $AUGUR_FACADE_REPO_DIRECTORY"
    echo "Using it in the config" 
    echo "IMPORTANT NOTE: This assumes that this directory already exists"
    echo "Please unset AUGUR_FACADE_REPO_DIRECTORY if you would like to be prompted for the facade repo directory"
      facade_repo_directory=$AUGUR_FACADE_REPO_DIRECTORY
    echo
    fi

    if [[ -z "${RABBITMQ_CONN_STRING}" ]]
    then
        get_rabbitmq_broker_url
    else
    echo
    echo "Found RABBITMQ_CONN_STRING environment variable with value $RABBITMQ_CONN_STRING"
    echo "Using it in the config" 
    echo "Please unset RABBITMQ_CONN_STRING if you would like to be prompted for the rabbit MQ connection string"
      rabbitmq_conn_string=$RABBITMQ_CONN_STRING
    echo
    fi
    
    #special case for docker entrypoint
    if [ $target = "docker" ]; then
      cmd=( augur config init --github-api-key $github_api_key --gitlab-api-key $gitlab_api_key --facade-repo-directory $facade_repo_directory --redis-conn-string $redis_conn_string --rabbitmq-conn-string $rabbitmq_conn_string )
      echo "init with redis $redis_conn_string"
    else
      cmd=( augur config init --github-api-key $github_api_key --gitlab-api-key $gitlab_api_key --facade-repo-directory $facade_repo_directory --rabbitmq-conn-string $rabbitmq_conn_string )
    fi


    

    #Create and cache credentials for github and gitlab
    touch $facade_repo_directory/.git-credentials
    
    echo "https://$github_username:$github_api_key@github.com" > $facade_repo_directory/.git-credentials
    echo "https://$gitlab_username:$gitlab_api_key@gitlab.com" >> $facade_repo_directory/.git-credentials

    git config --global credential.helper "store --file $facade_repo_directory/.git-credentials"
    "${cmd[@]}" 
}
echo
echo "Collecting data for config..."
create_config
echo
echo "Config created"
echo

# config_prompt




