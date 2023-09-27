# How to use:
# This is the basic command format:
# sh vicify.sh sample_name SE/PE hg19/hg38/T2T

## Where:
# sample_name - whatever comes before the "_1.fastq.gz"/"_2.fastq.gz" for paired-end or the ".fastq.gz" for single-end.
# SE - single-end, when only one FASTQ file is present
# PE - paired-end, when two FASTQ files are present
# T2T/hg38/hg19 - indicate if you are aligning reads to hg38 or hg19

## Crucial remarks regarding FASTQs:
# FASTQ files must be located within the "input_fastqs" folder.
# PE FASTQ files must be named yourSampleName_1.fastq.gz and yourSampleNumber_2.fastq.gz.
# e.g., for sample a1234 files must be named: a1234_1.fastq.gz and a1234_2.fastq.gz
# SE FASTQ files must be named yourSampleName.fastq.gz.
# e.g., for sample b1234 your FASTQ must be named: b1234.fastq.gz

# Examples:
# bash ViCiFy.sh a1234 PE T2T
# bash ViCiFy.sh b1234 SE hg38


# Good luck!

###################################

mkdir $1

if [ "$2" == "PE" ]; then
    cp "input_fastqs/$1_1.fastq.gz" "$1/$1_1.fastq.gz"
    cp "input_fastqs/$1_2.fastq.gz" "$1/$1_2.fastq.gz"
    cd "$1"
    java -Xmx32G -jar ../ViCiFierTools/picard.jar FastqToSam \
        -FASTQ $1_1.fastq.gz\
        -FASTQ2 $1_2.fastq.gz\
        -OUTPUT $1.unmapped.bam\
        -READ_GROUP_NAME H0164.2\
        -SAMPLE_NAME $1\
        -LIBRARY_NAME illumina\
        -PLATFORM_UNIT H0164ALXX140820.2\
        -PLATFORM illumina\
        -SEQUENCING_CENTER unknown\
        -TMP_DIR tmp_$1\
        -RUN_DATE 2021-04-06T15:49:15
elif [ "$2" == "SE" ]; then
    cp input_fastqs/$1.fastq.gz $1/$1.fastq.gz
    cd $1
    java -Xmx32G -jar ../ViCiFierTools/picard.jar FastqToSam \
        -FASTQ $1.fastq.gz\
        -OUTPUT $1.unmapped.bam\
        -READ_GROUP_NAME H0164.2\
        -SAMPLE_NAME $1\
        -LIBRARY_NAME illumina\
        -PLATFORM_UNIT H0164ALXX140820.2\
        -PLATFORM illumina\
        -SEQUENCING_CENTER unknown\
        -TMP_DIR tmp_$1\
        -RUN_DATE 2021-04-06T15:49:15
else
    echo "Please specify PE for paired-end or SE for single end as second parameter"
fi

rm -rf tmp_$1

SIZECHECK=$(du -h "$1.unmapped.bam" | cut -f1)
if [ "$SIZECHECK" == "0" ]; then
    if [ "$2" == "PE" ]; then
        gunzip $1_1.fastq.gz
        gunzip $1_2.fastq.gz
        trimmomatic PE $1_1.fastq $1_2.fastq $1_forward_paired.fq.gz $1_forward_unpaired.fq.gz $1_reverse_paired.fq.gz $1_reverse_unpaired.fq.gz ILLUMINACLIP:TruSeq3-PE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
        rm -f $1_1.fastq $1_2.fastq $1_forward_unpaired.fq.gz $1_reverse_unpaired.fq.gz
        java -Xmx8G -jar ../ViCiFierTools/picard.jar FastqToSam \
            FASTQ=$1_forward_paired.fq.gz\
            FASTQ2=$1_reverse_paired.fq.gz\
            OUTPUT=$1.unmapped.bam\
            READ_GROUP_NAME=H0164.2\
            SAMPLE_NAME=$1\
            LIBRARY_NAME=illumina\
            PLATFORM_UNIT=H0164ALXX140820.2\
            PLATFORM=illumina\
            SEQUENCING_CENTER=unknown\
            TMP_DIR=tmp_$1\
            RUN_DATE=2021-04-06T15:49:15
        rm -f $1_forward_paired.fq.gz $1_reverse_paired.fq.gz
    elif [ "$2" == "SE" ]; then
        gunzip $1.fastq.gz
        trimmomatic SE $1.fastq $1.fq.gz ILLUMINACLIP:TruSeq3-PE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
        rm -f $1.fastq
        java -Xmx8G -jar ../ViCiFierTools/picard.jar FastqToSam \
            FASTQ=$1.fq.gz\
            OUTPUT=$1.unmapped.bam\
            READ_GROUP_NAME=H0164.2\
            SAMPLE_NAME=$1\
            LIBRARY_NAME=illumina\
            PLATFORM_UNIT=H0164ALXX140820.2\
            PLATFORM=illumina\
            SEQUENCING_CENTER=unknown\
            TMP_DIR=tmp_$1\
            RUN_DATE=2021-04-06T15:49:15
        rm -f $1.fq.gz
    else
        echo "Please specify PE for paired-end or SE for single end as second parameter"
    fi
else
    echo "FASTQs are OK"
fi

rm -rf tmp_$1

java -Xmx32G -jar ../ViCiFierTools/picard.jar MarkIlluminaAdapters \
    -I $1.unmapped.bam\
    -O $1_markilluminaadapters.bam\
    -TMP_DIR tmp_$1\
    -M $1_markilluminaadapters_metrics.txt
rm -rf tmp_$1

java -Xmx32G -jar ../ViCiFierTools/picard.jar SamToFastq \
    -I $1_markilluminaadapters.bam\
    -FASTQ $1_samtofastq_interleaved.fq\
    -CLIPPING_ATTRIBUTE XT\
    -CLIPPING_ACTION 2\
    -INTERLEAVE true\
    -TMP_DIR tmp_$1\
    -NON_PF true
rm -rf tmp_$1

bwa mem -M -t 32 -p ../ViCiFierTools/references/$3.fa $1_samtofastq_interleaved.fq > $1_bwa_mem.sam

rm -f $1_1.fastq.gz $1_2.fastq.gz $1.fastq.gz $1_samtofastq_interleaved.fq $1_markilluminaadapters.bam $1_markilluminaadapters_metrics.txt

cd ..
java -Xmx32G -jar ViCiFierTools/picard.jar MergeBamAlignment \
    -R ViCiFierTools/references/$3.fa\
    -UNMAPPED_BAM $1/$1.unmapped.bam\
    -ALIGNED_BAM $1/$1_bwa_mem.sam\
    -O $1/$1_mergebamalignment.bam\
    -TMP_DIR $1/tmp_$1\
    -CREATE_INDEX true\
    -ADD_MATE_CIGAR true\
    -CLIP_ADAPTERS false\
    -CLIP_OVERLAPPING_READS true\
    -INCLUDE_SECONDARY_ALIGNMENTS true\
    -MAX_INSERTIONS_OR_DELETIONS -1\
    -PRIMARY_ALIGNMENT_STRATEGY MostDistant\
    -ATTRIBUTES_TO_RETAIN XS

cd $1
rm -f $1.unmapped.bam $1_bwa_mem.sam $1_samtofastq_interleaved.fq
rm -rf tmp_$1

mv $1_mergebamalignment.bam $1.bam
mv $1_mergebamalignment.bai $1.bai

cd ..
ViCiFierTools/gatk-4.4.0.0/gatk --java-options "-Xmx32g" HaplotypeCaller \
   -R ViCiFierTools/references/$3.fa\
   -I $1/$1.bam\
   -O $1/$1.vcf

cd $1
gzip $1.vcf
echo "Done"
