#!/bin/bash

set -x
{{
make_picard_demux_files.py \\
    -i "${sample_sheet}" \\
    -o "${params.out_prefix}"
}} 2>&1 | tee -a make_inputs.log
