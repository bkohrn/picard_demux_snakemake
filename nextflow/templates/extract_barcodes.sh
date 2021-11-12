#!/bin/bash

set -x

{
OUTDIR="${params.out_prefix}_picardExtractBarcodes"
mkdir \$OUTDIR

echo \$(picard ExtractIlluminaBarcodes --version)

picard -Xmx${params.mem_amount}${params.mem_type} \\
    ExtractIlluminaBarcodes \\
    BASECALLS_DIR=\$PWD/${params.in_dir}/Data/Intensities/BaseCalls/ \\
    BARCODE_FILE=${barcode_file} \\
    READ_STRUCTURE=${params.read_struct} \\
    LANE=${params.lane} \\
    OUTPUT_DIR=\$OUTDIR  \\
    METRICS_FILE=${params.out_prefix}_barcode_metrics.txt
} 2>&1 | tee -a extract_barcodes.log
