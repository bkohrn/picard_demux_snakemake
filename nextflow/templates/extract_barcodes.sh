#!/bin/bash

set -x

OUTDIR="${params.out_prefix}_picardExtractBarcodes"
mkdir \$OUTDIR

picard -Xmx${params.mem_amount}${params.mem_type} \
    ExtractIlluminaBarcodes \
    BASECALLS_DIR=\$PWD/BaseCalls/ \
    BARCODE_FILE=${barcode_file} \
    READ_STRUCTURE=${params.read_struct} \
    LANE=${params.lane} \
    OUTPUT_DIR=\$OUTDIR  \
    METRICS_FILE=${params.out_prefix}_barcode_metrics.txt
