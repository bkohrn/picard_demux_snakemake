#!/usr/bin/env python3

import argparse
from argparse import ArgumentParser

def main():
    # read parameters
    parser = ArgumentParser()
    parser.add_argument('-i','--input_file',
        dest='input',
        action="store",
        type=str,
        help="Input sample sheet",
        required=True)
    parser.add_argument(
        '-o','--out_prefix',
        dest='prefix',
        action="store",
        type=str,
        help="A prefix for output files",
        required=True)
    o = parser.parse_args()
    # make barcode file for picard ExtractIlluminaBarcodes
    # open output files
    # Open ExtractIlluminaBarcodes file
    out_eib = open(f"{o.prefix}_eib_barcode_file.txt", 'w')
    # Header for ExtractIlluminaBarcodes input
    ## library_name\tbarcode_name\tbarcode_sequence_1\tbarcode_sequence_2\n
    out_eib.write("library_name\tbarcode_name\tbarcode_sequence_1\tbarcode_sequence_2\n")
    # Open IlluminaBasecallsToFastq file
    out_btf = open(f"{o.prefix}_btf_multiplex_params.txt", 'w')
    # Header for IlluminaBasecallsToFastq
    ## OUTPUT_PREFIX\tlibrary_name\tbarcode_name\tBARCODE_1\tBARCODE_2\n
    out_btf.write("OUTPUT_PREFIX\tlibrary_name\tbarcode_name\tBARCODE_1\tBARCODE_2\n")
    # Open IlluminaBasecallsToSam file
    out_bts = open(f"{o.prefix}_bts_library_params.txt", 'w')
    # Header for IlluminaBasecallsToSam
    ## OUTPUT\tSAMPLE_ALIAS\tLIBRARY_NAME\tBARCODE_1\tBARCODE_2\n
    out_bts.write("OUTPUT\tSAMPLE_ALIAS\tLIBRARY_NAME\tBARCODE_1\tBARCODE_2\n")
    out_filesToMake = open(f"{o.prefix}_dirsToMake.txt", 'w')
    # Open sample sheet
    in_sample_sheet = open(o.input, 'r')
    line = next(in_sample_sheet).strip().strip(',')
    while line != "[Data]":
        line = next(in_sample_sheet).strip().strip(',')
    header_line = next(in_sample_sheet).strip().strip(',').split(',')
    for line in in_sample_sheet:
        line_dict = dict(zip(header_line, line.strip().strip(',').split(',')))
        out_eib.write(f"{line_dict['Sample_Name']}\t"
                      f"{line_dict['I7_Index_ID']}\t"
                      f"{line_dict['index']}\t"
                      f"{line_dict['index2']}\n")
        out_btf.write(f"fastq/{line_dict['Sample_Name']}/{line_dict['Sample_Name']}\t"
                      f"{line_dict['Sample_Name']}\t"
                      f"{line_dict['I7_Index_ID']}\t"
                      f"{line_dict['index']}\t"
                      f"{line_dict['index2']}\n")
        out_bts.write(f"sam/{line_dict['Sample_Name']}/{line_dict['Sample_Name']}_unmapped.bam\t"
                      f"{line_dict['Sample_Name']}\t"
                      f"{line_dict['I7_Index_ID']}\t"
                      f"{line_dict['index']}\t"
                      f"{line_dict['index2']}\n")
        out_filesToMake.write(
            f"sam/{line_dict['Sample_Name']}/\n"
            f"fastq/{line_dict['Sample_Name']}/\n")
    in_sample_sheet.close()
    out_eib.close()
    out_btf.close()
    out_bts.close()
    out_filesToMake.close()

if __name__ == "__main__":
    main()