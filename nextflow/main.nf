#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

// Set default parameters
params.in_dir = false  // User can provide their own in_dir with --in_dir WHATEVER_VALUE at runtime
params.out_prefix = false
params.read_struct = false
params.data_type = false
params.machine_name = false
params.flowcell_barcode = false
params.run_barcode = false
params.lane = false
params.num_lanes = 1
params.num_processors = false
params.compress_outputs = "true"
params.ignore_unexpected_barcodes = "true"
params.seq_center = false
params.mem_amount = 8
params.mem_type = "G"

// Set the containers to use for each component
params.container__python = "quay.io/fhcrc-microbiome/python-pandas:0fd1e29"
params.container__picardtools = "quay.io/biocontainers/picard:2.20.8--0"

// Import the processes defined in modules/processes.nf into the main workflow scope
include {
    check_directory;
    make_inputs;
    extract_barcodes;
    basecalls_to_fastq;
    basecalls_to_sam;
} from './modules/processes'

// Function which prints help message text
def helpMessage() {
    log.info"""
Usage:
nextflow run <REPO_URL> <ARGUMENTS>
Required Arguments:
  
  Input Data:
  ADD HELP TEXT HERE
    """.stripIndent()
}

log.info"""This pipeline started""".stripIndent()
// Main workflow
workflow {
    log.info"""This pipeline started""".stripIndent()
    // Check to make sure that all of the required inputs have been provided
    if ( params.in_dir == false || params.out_prefix == false || params.read_struct == false || params.data_type == false || params.machine_name == false || params.flowcell_barcode == false ){
        // Print the help message
        helpMessage()

        // Exit out
        exit 1
    }
    log.info"""Inputs look good""".stripIndent()
    // Primary input for all processes
    Channel
        .fromPath("${params.in_dir}")
        .set{
            basecalls_dir
        }
    log.info"""Set up data channel""".stripIndent()
    // Run the check_directory process, using all of the files from the basecalls folder
    check_directory (
        basecalls_dir
    )
     log.info"""directory checked""".stripIndent()
    // Make the inputs
    make_inputs (
        // Sample sheet
        Channel
            .fromPath("${params.in_dir}/SampleSheet.csv"),
        // Also wait for the check_directory process to finish (successfully)
        check_directory.out.out_good
    )

    // Extract the barcodes
    extract_barcodes(
        // Also wait for the check_directory process to finish (successfully)
        check_directory.out.out_good,
        // Include all of the files from the basecalls directory
        basecalls_dir,
        // Pipe in the barcode file
        make_inputs.out.out_eib
    )

    // convert to fastq
    basecalls_to_fastq(
        // Also wait for the check_directory process to finish (successfully)
        check_directory.out.out_good,
        // Include all of the files from the basecalls directory
        basecalls_dir,
        make_inputs.out.out_btf,
        extract_barcodes.out.barcodes_dir,
        make_inputs.out.out_dirsToMake
    )

    // convert to sam
    basecalls_to_sam(
        // Also wait for the check_directory process to finish (successfully)
        check_directory.out.out_good,
        // Include all of the files from the basecalls directory
        basecalls_dir,
        make_inputs.out.out_bts,
        extract_barcodes.out.barcodes_dir,
        make_inputs.out.out_dirsToMake
    )
}