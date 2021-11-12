#!/bin/bash

set -x

for dirIter in \$(cat ${dirs_to_make}); do
    mkdir -p \${dirIter}
done

picard -Xmx${params.mem_amount}${params.mem_type} IlluminaBasecallsToFastq \\
BASECALLS_DIR=\$PWD/${params.in_dir}/Data/Intensities/BaseCalls/ \\
BARCODES_DIR=\$PWD/Barcodes_dir/ \\
READ_STRUCTURE=${params.read_struct} \\
LANE=${params.lane} \\
MULTIPLEX_PARAMS=${multiplex_params} \\
MACHINE_NAME=${params.machine_name} \\
RUN_BARCODE=${params.run_barcode} \\
FLOWCELL_BARCODE=${params.flowcell_barcode} \\
NUM_PROCESSORS=${params.num_processors} \\
COMPRESS_OUTPUTS=${params.compress_outputs} \\
IGNORE_UNEXPECTED_BARCODES=${params.ignore_unexpected_barcodes}