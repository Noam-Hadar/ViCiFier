## Prepare an environment for (FASTQ -> BAM+VCF) pipeline
# Prerequisites: BWA, samtools, trimmomatic
# Installation of prerequisites (ubuntu): sudo apt-get install bwa samtools trimmomatic
# run this script using: bash ViCiFier_setup.sh
######################
mkdir ViCiFierTools
cd ViCiFierTools

##Picard & GATK
wget --no-check-certificate https://github.com/broadinstitute/picard/releases/download/3.1.0/picard.jar
wget --no-check-certificate https://github.com/broadinstitute/gatk/releases/download/4.4.0.0/gatk-4.4.0.0.zip
unzip gatk-4.4.0.0.zip
rm -f gatk-4.4.0.0.zip
echo "Picard & GATK downloaded"

##Download reference genomes - hg38 & hg19 & T2T
mkdir "references"
cd "references"
#T2T
wget --no-check-certificate https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/analysis_set/chm13v2.0.fa.gz -O T2T.fa.gz
gunzip T2T.fa.gz
bwa index T2T.fa

#hg38
wget --no-check-certificate https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz -O hg38.fa.gz
gunzip hg38.fa.gz
bwa index hg38.fa

#hg19
wget --no-check-certificate https://hgdownload.soe.ucsc.edu/goldenPath/hg19/bigZips/hg19.fa.gz -O hg19.fa.gz
gunzip hg19.fa.gz
bwa index hg19.fa

#Create dict files for each reference genome
cd ..

java -jar picard.jar CreateSequenceDictionary -R references/T2T.fa -O references/T2T.dict
samtools faidx references/T2T.fa

java -jar picard.jar CreateSequenceDictionary -R references/hg38.fa -O references/hg38.dict
samtools faidx references/hg38.fa

java -jar picard.jar CreateSequenceDictionary -R references/hg19.fa -O references/hg19.dict
samtools faidx references/hg19.fa

cd ..
mkdir "input_fastqs"
echo "Done"
