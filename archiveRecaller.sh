#!/bin/bash

####################	Help Message	####################
Help()
{
	# Display help message
	echo "This script will check the archival status of files given a user-provided list and recall any files currently archived"
	echo "Not a SLURM batch script"
	echo 
	echo "Usage:"
	echo '	/path/to/archiveRecaller.sh [listOfFiles]'
	echo 
	echo "Argument Descriptions:"
	echo "	[-h]				Print this message"
	echo "	[listOfFiles]		The user-provided list of files to check archival status and initiate recall"
	echo 
	echo "Usage Example:"
	echo '	~/subscriptr/archiveRecaller.sh fileList.txt'
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
echo "#                   Archive Recall Check                  #"
echo "###########################################################"
echo 

# Set variable to hold the file with list of files to check and recall
listOfFiles=$1

# Function that loops through list of files and checks if they are
# already archived, if so begins the recall
recallCounter=0
activeCounter=0

archiveCheck() {
	while read -r file
	do

		# Check the archive status of the file
		isArchived=$(archive --status "${file}" | cut -d ' ' -f 1)

		# If the file has been archived, initiate the recall and count it
		if [ "$isArchived" = "Archived" ]; then
			archive --recall "${file}"
			let recallCounter+=1
			sleep 2
		fi

		if [ "$isArchived" = "Active" ]; then
			let activeCounter+=1
			sleep 2
		fi

	done < "${listOfFiles}"
}

# Call the function
archiveCheck

# Output information on which have been archived and which haven't
echo 
echo "Recall Initiated  ===>  ${recallCounter}"
echo 
echo "Active Status     ===>  ${activeCounter}"
echo 
echo "###########################################################"
echo 
