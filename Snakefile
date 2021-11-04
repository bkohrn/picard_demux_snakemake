import pandas as pd
from snakemake.utils import validate
from datetime import datetime
import sys

run_time = datetime.now().strftime("%Y%m%d%H%M%S")

configfile: f"{sys.path[0]}/config.yaml"

rule all:
    input:
        f".{config['out_prefix']}_basecalls_to_sam",
        f".{config['out_prefix']}_basecalls_to_fastq"
    output:
        tmpOut = touch(".done")

rule check_directory:
    params:
        read_struct = config['read_struct'],
        num_lanes = config['num_lanes'], 
        data_type = config['data_type'],
        mem_amount = config['mem_amount'],
        mem_type = config['mem_type'],
    input:
        basecalls_dir = f"{config['in_dir']}/Data/Intensities/BaseCalls/",
    output:
        check_good = temp(touch(f".{config['out_prefix']}.checkIlluminaDirectory_good"))
    conda:
        "envs/picardEnv.yaml"
    log:
        f"log/{config['out_prefix']}_check_illumina_directory_{run_time}.log"
    shell:
        """
        set -x
        {{
        picard -Xmx{params.mem_amount}{params.mem_type} CheckIlluminaDirectory \
        BASECALLS_DIR={input.basecalls_dir}/ \
        READ_STRUCTURE={params.read_struct} \
        LANES={params.num_lanes} \
        DATA_TYPES={params.data_type}
        }} 2>&1 | tee -a {log}
        """

rule make_inputs:
    params:
        basePath = sys.path[0],
        prefix = config['out_prefix']
    input:
        good_dir = f".{config['out_prefix']}.checkIlluminaDirectoy_good",
        sample_sheet = f"{config['in_dir']}/SampleSheet.csv"
    output:
        out_eib = f"{config['out_prefix']}_eib_barcode_file.txt",
        out_btf = f"{config['out_prefix']}_btf_multiplex_params.txt",
        out_bts = f"{config['out_prefix']}_bts_library_params.txt",
        out_dirsToMake = f"{config['out_prefix']}_dirsToMake.txt"
    conda:
        "envs/pythonEnv.yaml"
    log:
        f"log/{config['out_prefix']}_make_inputs_{run_time}.log"
    shell:
        """
        set -x
        {{
        python3 {params.basePath}/scripts/make_picard_demux_files.py \
        -i {input.sample_sheet} \
        -o {params.prefix}
        }} 2>&1 | tee -a {log}
        """

rule extract_barcodes:
    params:
        read_struct = config['read_struct'],
        lane = config['lane'],
        mem_amount = config['mem_amount'],
        mem_type = config['mem_type'],
    input:
        good_dir = f".{config['out_prefix']}.checkIlluminaDirectoy_good",
        basecalls_dir = f"{config['in_dir']}/Data/Intensities/BaseCalls/", 
        barcode_file = f"{config['out_prefix']}_eib_barcode_file.txt"
    output:
        out_dir = directory(f"{config['out_prefix']}_picardExtractBarcodes"),
        metrics_file = f"{config['out_prefix']}_barcode_metrics.txt",
        check_good = temp(touch(f".{config['out_prefix']}_extract_barcodes"))
    conda:
        "envs/picardEnv.yaml"
    log:
        f"log/{config['out_prefix']}_extract_barcodes_{run_time}.log"
    shell:
        """
        set -x
        {{
        mkdir {output.out_dir}
        picard -Xmx{params.mem_amount}{params.mem_type} ExtractIlluminaBarcodes \
        BASECALLS_DIR={input.basecalls_dir} \
        BARCODE_FILE={input.barcode_file} \
        READ_STRUCTURE={params.read_struct} \
        LANE={params.lane} \
        OUTPUT_DIR={output.out_dir}  \
        METRICS_FILE={output.metrics_file}
        }} 2>&1 | tee -a {log}
        """

rule make_directories:
    input:
        in_dirsToMake = f"{config['out_prefix']}_dirsToMake.txt",
        good_dir = f".{config['out_prefix']}.checkIlluminaDirectoy_good",
    output:
        out_fastqdir = directory(f"{config['out_prefix']}/fastq"),
        out_samdir = directory(f"{config['out_prefix']}/sam"),
        out_done = touch(temp(f".{config['out_prefix']}_dirsMade"))
    log:
        f"log/{config['out_prefix']}_mkdirs_{run_time}.log"
    shell:
        """
        set -x
        {{
        for dirIter in $(cat {input.in_dirsToMake}); do
            mkdir -p $dirIter
        done
        }} 2>&1 | tee -a {log}
        """

rule basecalls_to_fastq:
    params:
        read_struct = config['read_struct'],
        lane = config['lane'],
        mem_amount = config['mem_amount'],
        mem_type = config['mem_type'],
        machine_name = config["machine_name"],
        run_barcode = config["run_barcode"],
        flowcell_barcode = config["flowcell_barcode"],
        num_processors = config["num_processors"],
        compress_outputs = config["compress_outputs"],
        ignore_unexpected_barcodes = config["ignore_unexpected_barcodes"]
    input:
        good_dir = f".{config['out_prefix']}.checkIlluminaDirectoy_good",
        basecalls_dir = f"{config['in_dir']}/Data/Intensities/BaseCalls/", 
        barcodes_dir = f"{config['out_prefix']}_picardExtractBarcodes",
        multiplex_params = f"{config['out_prefix']}_btf_multiplex_params.txt",
        dirs_made = f".{config['out_prefix']}_dirsMade"
    output:
            check_good = temp(touch(f".{config['out_prefix']}_basecalls_to_fastq"))
    conda:
        "envs/picardEnv.yaml"
    log:
        f"log/{config['out_prefix']}_basecalls_to_fastq_{run_time}.log"
    shell:
        """
        set -x
        {{
        picard -Xmx{params.mem_amount}{params.mem_type} IlluminaBasecallsToFastq \
        BASECALLS_DIR={input.basecalls_dir} \
        BARCODES_DIR={input.barcodes_dir} \
        READ_STRUCTURE={params.read_struct} \
        LANE={params.lane} \
        MULTIPLEX_PARAMS={input.multiplex_params} \
        MACHINE_NAME={params.machine_name} \
        RUN_BARCODE={params.run_barcode} \
        FLOWCELL_BARCODE={params.flowcell_barcode} \
        NUM_PROCESSORS={params.num_processors} \
        COMPRESS_OUTPUTS={params.compress_outputs} \
        IGNORE_UNEXPECTED_BARCODES={params.ignore_unexpected_barcodes}
        }} 2>&1 | tee -a {log}
        """

rule basecalls_to_sam:
    params:
        read_struct = config['read_struct'],
        lane = config['lane'],
        mem_amount = config['mem_amount'],
        mem_type = config['mem_type'],
        machine_name = config["machine_name"],
        run_barcode = config["run_barcode"],
        flowcell_barcode = config["flowcell_barcode"],
        num_processors = config["num_processors"],
        compress_outputs = config["compress_outputs"],
        ignore_unexpected_barcodes = config["ignore_unexpected_barcodes"],
        seq_center = config["seq_center"]
    input:
        good_dir = f".{config['out_prefix']}.checkIlluminaDirectoy_good",
        basecalls_dir = f"{config['in_dir']}/Data/Intensities/BaseCalls/", 
        barcodes_dir = f"{config['out_prefix']}_picardExtractBarcodes",
        library_params = f"{config['out_prefix']}_bts_library_params.txt",
        dirs_made = f".{config['out_prefix']}_dirsMade"
    output:
        check_good = temp(touch(f".{config['out_prefix']}_basecalls_to_sam"))

    conda:
        "envs/picardEnv.yaml"
    log:
        f"log/{config['out_prefix']}_baecalls_to_sam_{run_time}.log"
    shell:
        """
        set -x
        {{
        picard -Xmx{params.mem_amount}{params.mem_type} IlluminaBasecallsToSam \
        BASECALLS_DIR={input.basecalls_dir} \
        BARCODES_DIR={input.barcodes_dir} \
        READ_STRUCTURE={params.read_struct} \
        LANE={params.lane} \
        LIBRARY_PARAMS={input.library_params} \
        RUN_BARCODE={params.run_barcode} \
        SEQUENCING_CENTER={params.seq_center} \
        NUM_PROCESSORS={params.num_processors} \
        IGNORE_UNEXPECTED_BARCODES={params.ignore_unexpected_barcodes}
        }} 2>&1 | tee -a {log}
        """