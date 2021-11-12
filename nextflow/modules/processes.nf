#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2


// process TEMPLATE {
//     container "${params.container__FOOBAR}"

//     input:

//     outputs:

//     scripts:
//     template: ''

// }

process check_directory {
    container "${params.container__picardtools}"
    publishDir "${params.out_prefix}/logs/", mode: "copy", overwrite: true, pattern: "check_illumina_directory.log"

    input:
    path "*"

    outputs:
    path ".checkIlluminaDirectory_good"
    path "check_illumina_directory.log"

    scripts:
    template: 'check_directory.sh'

}


process make_inputs {
    container "${params.container__python}"
    publishDir "${params.out_prefix}/logs/", mode: "copy", overwrite: true, pattern: "make_inputs.log"

    input:
    path sample_sheet
    path "*"

    outputs:
    path "make_inputs.log", emit: log
    path "${params.out_prefix}_eib_barcode_file.txt", emit: out_eib
    path "${params.out_prefix}_btf_multiplex_params.txt", emit: out_btf
    path "${params.out_prefix}_bts_library_params.txt", emit: out_bts
    path "${params.out_prefix}_dirsToMake.txt", emit: out_dirsToMake

    scripts:
    template: 'make_inputs.sh'

}


process extract_barcodes {
    container "${params.container__picard}"

    input:
    path "checkIlluminaDirectory_good"
    path "BaseCalls/*"
    path barcode_file

    outputs:
    path "${params.out_prefix}_picardExtractBarcodes/*", emit: barcodes_dir
    path "${params.out_prefix}_barcode_metrics.txt", emit: barcode_metrics

    scripts:
    template: 'extract_barcodes.sh'

}
