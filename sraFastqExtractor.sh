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
	echo "This script will dump the FASTQs from SRA data into a subdirectory based on user-provided path"
	echo "to directory that contains SRA data files"
	echo 
	echo "Usage:"
	echo '	sbatch --job-name=[jobName] --mail-user=[email] /path/to/sraFastqExtractor.sh [sraFileDir]'
	echo 
	echo "Argument Descriptions:"
	echo "	[-h]		Print this message"
	echo "	[jobName]	The name of the SLURM job, must be unique"
	echo "	[email]		The user's email address to receive notifications"
	echo "	[sraFileDir]	The absolute path to the directory that contains .sra files to fastq-dump'"
	echo 
	echo "Usage Example:"
	echo '	sbatch --job-name=test --mail-user=example@nyulangone.org ~/subscriptr/sraFastqExtractor.sh /gpfs/scratch/username/ncbi/sra/batchToFastqDump/'
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
echo "#                      SRA FASTQ-dump                     #"
echo "###########################################################"
echo 

# Load SRA Toolkit module to environment
module add sratoolkit/2.9.1

# List modules for quick debugging
module list -t
echo 

# Set variables to hold user defined subdirectory that contains input .sra files
# and where a subdirectory will be made for the FASTQs output directory and the completed .sra extractions
sraSubdir=$1
fastqDir="${sraSubdir}fastqs"
sraCompletedDir="${sraSubdir}completedExtraction"

# Make directory FASTQ output directory and completed extraction directory
# if they don't exist
mkdir -p "$fastqDir"
mkdir -p "$sraCompletedDir"

# Create a function that downloads FASTQ files using .sra file
fastqExtraction() {
	for sraFile in "${sraSubdir}"*".sra"
	do	

		# Get the FASTQ formatted reads from the SRA, https://edwards.sdsu.edu/research/fastq-dump/
		fastq-dump "${sraFile}" --origfmt --skip-technical --read-filter pass --split-3 --gzip -O "${fastqDir}" 
		
		# Move used .sra file to completed subdirectory
		mv "${sraFile}" "${sraCompletedDir}"

	done
}

# Call the function
fastqExtraction

echo 
echo "###########################################################"
echo 
