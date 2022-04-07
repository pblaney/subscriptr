#!/bin/bash

#SBATCH --partition=cpu_medium
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=6G
#SBATCH --time=5-00:00:00
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --output=sraPrefetch-%x.log

####################	Help Message	####################
Help()
{
	# Display help message
	echo "This script will prefetch SRA data into a subdirectory based on user-provided:"
	echo "1) list of accession IDs, 2) path to SRA-configured directory, 3) job name for capturing failed downloads"
	echo 
	echo "Usage:"
	echo '	sbatch --job-name=[jobName] --mail-user=[email] /path/to/sraFilePrefetcher.sh [sraAccessionList] [sraDir] [jobName]'
	echo 
	echo "Argument Descriptions:"
	echo "	[-h]			Print this message"
	echo "	[jobName]		The name of the SLURM job, must be unique"
	echo "	[email]			The user's email address to receive notifications"
	echo "	[sraAccessionList]	The user-provided text file with SRA accession IDs (one ID per line, no header)"
	echo "	[sraDir]		The absolute path to the 'sra/' directroy, must be SRA-configured with command 'vdb-config -i'"
	echo 
	echo "Usage Example:"
	echo '	sbatch --job-name=test --mail-user=example@nyulangone.org ~/subscriptr/sraFilePrefetcher.sh sraAccessionList.txt /gpfs/scratch/username/ncbi/sra/ test'
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
echo "#                       SRA Prefetch                      #"
echo "###########################################################"
echo 

# Load SRA Toolkit module
module add sratoolkit/2.9.1

# List modules for quick debugging
module list -t
echo 

# Set variables to hold the file that contains SRA accession IDs, the SRA
# directory that will then be used to create subdirectories for each run,
# and the job name to parse the log file for failed jobs.
sraListFile=$1
sraDir=$2
jobName=$3
sraSubdirName="${sraListFile/.*/}"
sraSubdir="${sraDir}${sraSubdirName}"
mkdir -p "${sraSubdir}"

# Function that loops through list of SRA accession IDs and prefetches each .sra
# file in a subset of full dataset
sraPrefetch() {
	while read -r sraAccession
	do
		# Get the .sra file
		prefetch --max-size 500G "${sraAccession}"
		
		# Move .sra file into subdirectory 
		mv "${sraDir}${sraAccession}"* "${sraSubdir}" 

	done < "${sraListFile}"
}

# Call the function
sraPrefetch

# Create list of any files that failed the download
grep "failed to download" sraPrefetch-"${jobName}".log | sed -e 's,.*failed to download ,,' > failedDownloads-"${jobName}".err

echo 
echo "###########################################################"
echo 
