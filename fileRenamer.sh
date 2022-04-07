#!/bin/bash

####################	Help Message	####################
Help()
{
	# Display help message
	echo "This script will rename files within a user-defined directory based on user-provided file of names"
	echo "Not a SLURM batch script"
	echo 
	echo "WARNING: Tread carefully as the script will not account for odd/unseen characters in new filenames"
	echo 
	echo "Usage:"
	echo '	/path/to/fileRenamer.sh [fileOfNames]'
	echo 
	echo "Argument Descriptions:"
	echo "	[-h]		Print this message"
	echo "	[fileOfNames]	The user-provided text file with old and new filenames (one set of tab-separated old and new filenames, no header)"
	echo 
	echo "Usage Example:"
	echo '	~/subscriptr/fileRenamer.sh filenameList.txt'
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

# Set variable to name of file containing old and new names
nameFile=$1

# Function that will parse through file and change name of file from old to new
renamer() {
	while read -r fileOfNames
	do
		# Parse each line for the old name and the new name
		oldname=$(echo "${fileOfNames}" | cut -f 1)
		newname=$(echo "${fileOfNames}" | cut -f 2)

		# Print name change for debugging
		echo "${oldname}  ~~~>  ${newname}"

		# Issue the renaming command
		mv "${oldname}" "${newname}"

	done < "${nameFile}"
}

# Call function
renamer 1>renamedFiles.log