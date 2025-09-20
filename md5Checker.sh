#!/bin/bash

#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=2G
#SBATCH --time=8:00:00
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --mail-user=patrick.blaney@nyulangone.org
#SBATCH --output=md5checksum-%x.log

####################	Help Message	####################
Help()
{
	# Display help message
	echo "This script will calculate the MD5 hash for all files matching the regex"
	echo 
	echo "Usage:"
	echo '	/path/to/md5Checker.sh [fileRegex] [md5checksumFile]'
	echo 
	echo "Argument Descriptions:"
	echo "	[-h]			Print this message"
	echo "	[fileRegex]		The user-provided regex to grab files to generate MD5 hash"
	echo "	[md5checksumFile]	Output file that will contain the per file MD5 hashes"
	echo 
	echo "Usage Example:"
	echo '	~/subscriptr/md5Checker.sh *.ba* test'
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
echo "#                  MD5 Checksum Generator                 #"
echo "###########################################################"
echo 

# Set variable to hold the file with list of files to check and recall
fileRegex=$1
md5checksumFile=$2

cmd="md5sum ${fileRegex} > md5sums-${md5checksumFile}.txt"
echo "CMD: ${cmd}"
eval "${cmd}"

echo 
echo "###########################################################"
echo 
