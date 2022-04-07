#!/bin/bash

#SBATCH --partition=cpu_long
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20
#SBATCH --mem-per-cpu=1G
#SBATCH --time=10-00:00:00
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --mail-user=patrick.blaney@nyulangone.org
#SBATCH --output=egaDataDownloader-%x.log

####################	Help Message	####################
Help()
{
	# Display help message
	echo "This script will download EGA data into a subdirectory based on user-provided:"
	echo "1) list of EGAF accession IDs, 2) path to EGA credentials JSON, 3) job name for capturing failed downloads"
	echo 
	echo "WARNING: This script expects the executible command 'pyega3' is on the user's PATH."
	echo "         See https://github.com/EGA-archive/ega-download-client"
	echo "	     https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html#creating-an-environment-with-commands"
	echo 
	echo "Usage:"
	echo '	sbatch --job-name=[jobName] /path/to/egaDataDownloader.sh [egafAccessionList] [egaCredentials] [jobName]'
	echo 
	echo "Argument Descriptions:"
	echo "	[-h]			Print this message"
	echo "	[jobName]		The name of the SLURM job, must be unique"
	echo "	[egafAccessionList]	The user-provided text file with EGAF accession IDs (one ID per line, no header)"
	echo "	[egaCredentials]	The user-provided JSON file with EGA login credentials, see https://ega-archive.org"
	echo 
	echo "Usage Example:"
	echo '	sbatch --job-name=test ~/subscriptr/egaDataDownloader.sh egafAccessionList.txt egaCredentials.json test'
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
echo "#                    EGA File Download                    #"
echo "###########################################################"
echo 

# List modules for quick debugging
module list -t
echo 

# Set variables to hold the file that contains EGA accession IDs, the user's EGA 
# login credentials JSON file, and the job name to parse the log file for failed jobs.
egaListFile=$1
egaCredentials=$2
jobName=$3

# Function that loops through list of EGA dataset filenames and downloads
# each file in a subset of full dataset
egaDownloader() {
	while read -r egaFileAccession
	do
		# Get each EGA file
		# Issue the samtools view command
		cmd="
		pyega3 \
		-cf ${egaCredentials} \
		-c 20 \
		fetch ${egaFileAccession} \
		--max-retries 50 \
		--retry-wait 10
		"
		echo "CMD: ${cmd}"
		eval "${cmd}"
		echo 

	done < "${egaListFile}"
}

# Call the downloader function
egaDownloader

# Give time for PyEGA output log to be printed
sleep 10

# Create list of any files that failed the download
grep 'Saved to' pyega3_output.log > successfulDownloads-"${jobName}".tmp1 && \
sed 's|\[.*egad...........\/||' successfulDownloads-"${jobName}".tmp1 > successfulDownloads-"${jobName}".tmp2 && \
rm successfulDownloads-"${jobName}".tmp1 && \
sed 's|\/.*||' successfulDownloads-"${jobName}".tmp2 > successfulDownloads-"${jobName}".out && \
rm successfulDownloads-"${jobName}".tmp2 && \
comm -13 successfulDownloads-"${jobName}".out "${egaListFile}" > failedDownloads-"${jobName}".out

echo 
echo "###########################################################"
echo 
