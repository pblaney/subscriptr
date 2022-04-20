#!/bin/bash

#SBATCH --partition=cpu_short
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4G
#SBATCH --time=6:00:00
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --output=vcfSampleExtractor-%x.log

####################	Help Message	####################
Help()
{
	# Display help message
	echo "This script will subset a VCF by a user-provided sample name and produce a VCF containing only that sample"
	echo 
	echo "Usage:"
	echo '	sbatch --job-name=[jobName] --mail-user=[email] /path/to/vcfSampleExtractor.sh [sample] [inputVcf] [filterExpression]'
	echo 
	echo "Argument Descriptions:"
	echo "	[-h]			Print this message"
	echo "	[jobName]		The name of the SLURM job, must be unique"
	echo "	[email]			The user's email address to receive notifications"
	echo "	[sample]		The user-provided sample name that they wish to extract from the input VCF"
	echo "	[inputVcf]		The user-provided multi-sample VCF"
	echo "	[filterExpression]	The user-provided filter expression to use for further extraction (default is to remove homozygous ref genotypes ""'"'GT="'"0|0"'"'"')"
	echo 
	echo "Usage Example:"
	echo "	sbatch --job-name=test --mail-user=example@nyulangone.org ~/subscriptr/vcfSampleExtractor.sh /gpfs/scratch/username/input.vcf ""'"'GT="'"0|0"'"'"'"
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
echo "#                      BCFtools view                      #"
echo "###########################################################"
echo 

# Load BCFtools module
module add bcftools/1.13

# List modules for quick debugging
module list -t
echo 

# Set variable for user-defined sample name to extract, and the input VCF
sample=$1
inputVcf=$2
filterExpression=${3}

# Issue the BCFtools command
cmd="
bcftools view \
--output-type u \
--samples ${sample} \
${inputVcf} \
| \
bcftools filter \
--output-type v \
--output ${sample}.vcf \
--exclude '${filterExpression}'
"
echo "CMD: ${cmd}"
eval "${cmd}"

echo 
echo "###########################################################"
echo 
