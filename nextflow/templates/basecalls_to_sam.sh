#!/bin/bash

set -x

for dirIter in \$(cat ${dirs_to_make}); do
    mkdir -p \${dirIter}
done

picard -Xmx${params.mem_amount}${params.mem_type} IlluminaBasecallsToSam \\
BASECALLS_DIR=\$PWD/${params.in_dir}/Data/Intensities/BaseCalls/ \\
BARCODES_DIR= \$PWD/Barcodes_dir/ \\
READ_STRUCTURE=${params.read_struct} \\
LANE=${params.lane} \\
LIBRARY_PARAMS=${library_params} \\
RUN_BARCODE=${params.run_barcode} \\
SEQUENCING_CENTER=${params.seq_center} \\
NUM_PROCESSORS=${params.num_processors} \\
IGNORE_UNEXPECTED_BARCODES=${params.ignore_unexpected_barcodes}