#!/bin/bash

#SBATCH --partition=cpu_medium
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=6G
#SBATCH --time=1-00:00:00
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --output=sraPrefetch-%x.log

####################	Help Message	####################
Help()
{
	# Display help message
	echo "This script will prefetch SRA data into a subdirectory based on user-provided:"
	echo "1) list of accession IDs, 2) optionally, the path to the .ngc file"
	echo 
	echo "Usage:"
	echo '	sbatch --job-name=[jobName] --mail-user=[email] /path/to/sraFilePrefetcher.sh [sraAccessionList] [ngcFilePath]'
	echo 
	echo "Argument Descriptions:"
	echo "	[-h]			Print this message"
	echo "	[jobName]		The name of the SLURM job, must be unique"
	echo "	[email]			The user's email address to receive notifications"
	echo "	[sraAccessionList]	The user-provided text file with SRA accession IDs (one ID per line, no header)"
	echo "	[ngcFilePath]		Optional: The absolute path to the .ngc file for decrypting access controlled data"
	echo 
	echo "Usage Example:"
	echo '	sbatch --job-name=test --mail-user=example@nyulangone.org ~/subscriptr/sraFilePrefetcher.sh sraAccessionList.txt'
	echo 
	echo '	~~~ OR ~~~'
	echo 
	echo '	sbatch --job-name=test --mail-user=example@nyulangone.org ~/subscriptr/sraFilePrefetcher.sh sraAccessionList.txt ~/prj_test.ngc'
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
module add sratoolkit/2.10.9

# List modules for quick debugging
module list -t
echo 

# Set variables to hold the file that contains SRA accession IDs, and 
# optionally the path to the .ngc file for access controlled data (e.g. dbGaP data)
sraListFile=$1
ngcFilePath=${2:-""}

# Function that loops through list of SRA accession IDs and prefetches each .sra
# file in a subset of full dataset
sraPrefetch() {
	while read -r sraAccession
	do
		# Get the .sra file
		if [[ ${ngcFilePath} != "" ]]; then

			prefetch "${sraAccession}" \
			--progress \
			--resume yes \
			--max-size 500G \
			--log-level debug \
			--ngc "${ngcFilePath}"

		else

			prefetch "${sraAccession}" \
			--progress \
			--resume yes \
			--max-size 500G \
			--log-level debug

		fi

	done < "${sraListFile}"
}

# Override vdb-config setup to download SRA files to current working directory
vdb-config --prefetch-to-cwd

# Call the function
sraPrefetch

# Output helpful log information based on successful and failed downloads
sleep 7

totalSraAccession=$(cat ${sraListFile} | wc -l)
successfulDownloads=$(grep -E "SRR.*[1-9]' was downloaded successfully" sraPrefetch-"${SLURM_JOB_NAME}".log | wc -l)

if [[ ${successfulDownloads} == ${totalSraAccession} ]]; then
	echo 
	echo "Total       ===> ${totalSraAccession}"
	echo 
	echo "Successful  ===> ${successfulDownloads}"
else
	failedDownloads=$(grep "failed to download" sraPrefetch-"${SLURM_JOB_NAME}".log | wc -l)
	grep "failed to download" sraPrefetch-"${SLURM_JOB_NAME}".log | sed -e 's|.*failed to download ||' > failedDownloads-"${SLURM_JOB_NAME}".err

	echo 
	echo "Total       ===> ${totalSraAccession}"
	echo 
	echo "Successful  ===> ${successfulDownloads}"
	echo 
	echo "Failed      ===> ${failedDownloads}"
fi

echo 
echo "###########################################################"
echo 
