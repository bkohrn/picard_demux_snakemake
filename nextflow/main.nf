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
params.run_barcode = 115
params.lane = "001"
params.num_lanes = 1
params.num_processors = -4
params.compress_outputs = "true"
params.ignore_unexpected_barcodes = "true"
params.seq_center = "My_Lab"
params.mem_amount = 16
params.mem_type = "G"

// Set the containers to use for each component
params.container__python = "quay.io/fhcrc-microbiome/python-pandas:0fd1e29"
params.container__picardtools = "quay.io/biocontainers/picard:2.26.4--hdfd78af_0"

// Import the processes defined in modules/processes.nf into the main workflow scope
include {
    check_directory;
    make_inputs;
    extract_barcodes
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

// Main workflow
workflow {

    // Check to make sure that all of the required inputs have been provided
    if ( params.in_dir == false || params.out_prefix == false || params.read_struct == false || params.data_type == false || params.machine_name == false || params.flowcell_barcode == false ){
        // Print the help message
        helpMessage()

        // Exit out
        exit 1
    }

    // Primary input for all processes
    Channel
        .fromPath("${params.in_dir}/Data/Intensities/BaseCalls/**")
        .set{
            basecalls_dir
        }

    // Run the check_directory process, using all of the files from the basecalls folder
    check_directory(
        basecalls_dir
    )

    // Make the inputs
    make_inputs(
        // Sample sheet
        Channel
            .fromPath("${params.in_dir}/SampleSheet.csv")
        // Also wait for the check_directory process to finish (successfully)
        check_directory.out
    )

    // Extract the barcodes
    extract_barcodes(
        // Also wait for the check_directory process to finish (successfully)
        check_directory.out
        // Include all of the files from the basecalls directory
        basecalls_dir
        // Pipe in the barcode file
        make_inputs.out.out_eib
    )

}