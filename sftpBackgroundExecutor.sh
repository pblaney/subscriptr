#!/bin/bash

####################	Help Message	####################
Help()
{
	# Display help message
	echo "This script will submit an SFTP command in the background given a user-provided list of commands, SSH key, and SFTP site"
	echo "Not a SLURM batch script"
	echo 
	echo "Usage:"
	echo '	/path/to/sftpBackgroundExecutor.sh [listOfCommands] [sshKeyPath] [sftpUsername@sftpSite.com]'
	echo 
	echo "Argument Descriptions:"
	echo "	[-h]				Print this message"
	echo "	[listOfCommands]		The user-provided list of SFTP commands to be executed in the background"
	echo "	[sshKeyPath]			The user-provided absolute path to the SFTP SSH key for the username that will be used"
	echo "	[sftpUsername@sftpSite.com]	The user-provided login username and associated SFTP site address"
	echo 
	echo "Usage Example:"
	echo '	~/subscriptr/sftpBackgroundExecutor.sh commandList.txt /gpfs/scratch/username/ssh_key username@remotesftp.com'
	echo 
}

while getopts ":h" option;
	do
		case $option in
			h) # Show help message
				Help
				exit;;
		    \?) # Reject other passed options
				echo "Invalid option"
				exit;;
		esac
	done

############################################################

# Debugging settings
set -euo pipefail

echo "###########################################################"
echo "#                 SFTP Background Executor                #"
echo "###########################################################"
echo 

# Set variable to hold the file with list of SFTP commands, the path
# to the username SSH key, and the SFTP site address
listOfCommands=$1
sshKeyPath=$2
sftpSite=$3

# Function that loops through list of SRA accession IDs and prefetches each .sra
# file in a subset of full dataset
counter=0
sftpBackgroundExeuction() {
	while read -r sftpCommand
	do
		# Increase counter
		let counter+=1

		# echo the SFTP command to be executed in the background to a temp file
		echo "${sftpCommand}" > "tempFile.command${counter}.txt"

		# Issue the sftp command
		cmd="sftp -b tempFile.command${counter}.txt -i ${sshKeyPath} ${sftpSite} &"
		echo "CMD: ${cmd}"
		eval "${cmd}"

		sleep 15

		echo 
		echo "###########################################################"
		echo

	done < "${listOfCommands}"
}

# Call the function
sftpBackgroundExeuction

echo "D O N E"
echo 
