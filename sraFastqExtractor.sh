#!/bin/bash

#SBATCH --partition=cpu_long
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=12G
#SBATCH --time=10-00:00:00
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --output=sraFastqExtraction-%x.log

####################	Help Message	####################
Help()
{
	# Display help message
	echo "This script will dump the FASTQs from SRA data within the specific SRA accession directory based on user-provided:"
	echo "1) list of accession IDs, 2) optionally, the path to the .ngc file"
	echo 
	echo "Usage:"
	echo '	sbatch --job-name=[jobName] --mail-user=[email] /path/to/sraFastqExtractor.sh [sraAccessionList] [ngcFilePath]'
	echo 
	echo "Argument Descriptions:"
	echo "	[-h]		Print this message"
	echo "	[jobName]	The name of the SLURM job, must be unique"
	echo "	[email]		The user's email address to receive notifications"
	echo "	[sraAccessionList]	The user-provided text file with SRA accession IDs (one ID per line, no header)"
	echo "	[ngcFilePath]		Optional: The absolute path to the .ngc file for decrypting access controlled data"
	echo 
	echo "Usage Example:"
	echo '	sbatch --job-name=test --mail-user=example@nyulangone.org ~/subscriptr/sraFastqExtractor.sh sraAccessionList.txt'
	echo 
	echo '	~~~ OR ~~~'
	echo '	sbatch --job-name=test --mail-user=example@nyulangone.org ~/subscriptr/sraFilePrefetcher.sh sraAccessionList.txt ~/prj_1234.ngc'
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
echo "#                     SRA Fasterq-dump                    #"
echo "###########################################################"
echo 

# Load SRA Toolkit module to environment
module add sratoolkit/2.10.9

# List modules for quick debugging
module list -t
echo 

# Set variables to hold the file that contains SRA accession IDs, and 
# optionally the path to the .ngc file for access controlled data (e.g. dbGaP data)
sraListFile=$1
ngcFilePath=${2:-""}

# Create a function that downloads FASTQ files using .sra file
fastqExtraction() {
	while read -r sraAccession
	do	
		# Move into accession-specific directory that contains .sra file
		cd ${sraAccession}/

		# Make temp directory
		mkdir -p tmp/

		# Get the FASTQ formatted reads from the SRA, https://edwards.sdsu.edu/research/fastq-dump/
		if [[ ${ngcFilePath} != "" ]]; then

			fasterq-dump "${sraAccession}" \
			--mem 2G \
			--temp tmp/ \
			--threads 8 \
			--progress \
			--log-level debug \
			--ngc "${ngcFilePath}"

		else

			fasterq-dump "${sraAccession}" \
			--mem 2G \
			--temp tmp/ \
			--threads 8 \
			--progress \
			--log-level debug

		fi
		
		# gzip each output FASTQ file
		echo 
		echo "Compressing FASTQs with Gzip...."
		gzip *.fastq

		# Remove temporary files
		echo 
		echo "Cleaning temp folder...."
		rm -rf tmp/*

		# Finish and bove back to base directory to begin next accession
		echo 
		echo "${sraAccession}  ===>  D O N E"
		echo 
		cd ../

	done < ${sraListFile}
}

# Call the function
fastqExtraction

# Output helpful log information based on successful and failed downloads
sleep 7

totalSraAccession=$(cat ${sraListFile} | wc -l)
successfulDownloads=$(grep -E "D O N E" sraFastqExtraction-"${SLURM_JOB_NAME}".log | wc -l)

if [[ ${successfulDownloads} == ${totalSraAccession} ]]; then
	echo 
	echo "Total       ===> ${totalSraAccession}"
	echo 
	echo "Successful  ===> ${successfulDownloads}"
else
	numberOfLeftovers=$(( ${totalSraAccession} - ${successfulDownloads} ))
	tail -n "${numberOfLeftovers}" ${sraListFile} > failedFasterqDump-"${SLURM_JOB_NAME}".err

	echo 
	echo "Total       ===> ${totalSraAccession}"
	echo 
	echo "Successful  ===> ${successfulDownloads}"
	echo 
	echo "Failed      ===> ${numberOfLeftovers}"
fi

echo 
echo "###########################################################"
echo 
