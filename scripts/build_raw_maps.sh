#!/bin/bash

## HiC-Pro
## Copyright (c) 2015-2018 Institut Curie                               
## Author(s): Nicolas Servant, Eric Viara
## Contact: nicolas.servant@curie.fr
## This software is distributed without any guarantee under the terms of the BSD-3 licence.
## See the LICENCE file for details

##
## build_raw_maps.sh
## Launcher for build_matrix C++ code
##

dir=$(dirname $0)

################### Initialize ###################

while [ $# -gt 0 ]
do
    case "$1" in
	(-c) conf_file=$2; shift;;
	(-h) usage;;
	(--) shift; break;;
	(-*) echo "$0: error - unrecognized option $1" 1>&2; exit 1;;
	(*)  break;;
    esac
    shift
done

################### Read the config file ###################

#read_config $ncrna_conf
CONF=$conf_file . $dir/hic.inc.sh

################### Define Input Directory ###################                                                                                                                                                 
input_data_type=$(get_data_type)

if [[ $input_data_type == "allvalid" ]]
then
    DATA_DIR=${RAW_DIR}
else
    DATA_DIR=${MAPC_OUTPUT}/data/
fi

nbf=$(find -L ${DATA_DIR} -mindepth 1 | wc -l)
if [[ $nbf == 0 ]]; then die "Error : empty ${DATA_DIR} folder."; fi

################### Define Variables ###################

GENOME_SIZE_FILE=`abspath $GENOME_SIZE`
if [[ ! -e $GENOME_SIZE_FILE ]]; then
    GENOME_SIZE_FILE=$ANNOT_DIR/$GENOME_SIZE
    if [[ ! -e $GENOME_SIZE_FILE ]]; then
	echo "$GENOME_SIZE not found. Exit"
	exit -1
    fi
fi

################### Create Matrix files ###################

for RES_FILE_NAME in ${DATA_DIR}/*
do
    RES_FILE_NAME=$(basename $RES_FILE_NAME)

    ## Logs
    ldir=${LOGS_DIR}/${RES_FILE_NAME}
    mkdir -p ${ldir}
    echo "Logs: ${ldir}/build_raw_maps.log"
    
    if [ -d ${DATA_DIR}/${RES_FILE_NAME} ]; then
	MATRIX_DIR=${MAPC_OUTPUT}/matrix/${RES_FILE_NAME}/raw
	for bsize in ${BIN_SIZE}
	do
	    if [[ ${bsize} == -1 ]]; then
		GENOME_FRAGMENT_FILE=`abspath $GENOME_FRAGMENT`
		if [[ $GENOME_FRAGMENT == "" || ! -f $GENOME_FRAGMENT_FILE ]]; then
		    GENOME_FRAGMENT_FILE=$ANNOT_DIR/$GENOME_FRAGMENT
		    if [[ ! -f $GENOME_FRAGMENT_FILE ]]; then
			echo "GENOME_FRAGMENT not found. Cannot generate fragment level Hi-C map"
			exit 1
		    fi
		fi
		bsize_opts="--binfile ${GENOME_FRAGMENT_FILE}"
		bsize="rfbin"
	    else
		bsize_opts=" --binsize ${bsize}"
	    fi
	    mkdir -p ${MATRIX_DIR}/${bsize}
	    echo "## Generate contact maps at $bsize resolution ..." >> ${ldir}/build_raw_maps.log
	    
	    ## Capture Hi-C experiments
	    if [[ ! -z ${CAPTURE_TARGET} ]]; then
		if [[ ! -z ${ALLELE_SPECIFIC_SNP} ]]; then
		    cmd="cat ${DATA_DIR}/${RES_FILE_NAME}/${RES_FILE_NAME}_ontarget_G1.allValidPairs | ${SCRIPTS}/build_matrix --matrix-format ${MATRIX_FORMAT} ${bsize_opts} --chrsizes $GENOME_SIZE_FILE --ifile /dev/stdin --oprefix ${MATRIX_DIR}/${bsize}/${RES_FILE_NAME}_${bsize}_G1"
		    exec_cmd $cmd >> ${ldir}/build_raw_maps.log 2>&1
		    cmd="cat ${DATA_DIR}/${RES_FILE_NAME}/${RES_FILE_NAME}_ontarget_G2.allValidPairs | ${SCRIPTS}/build_matrix --matrix-format ${MATRIX_FORMAT} ${bsize_opts} --chrsizes $GENOME_SIZE_FILE --ifile /dev/stdin --oprefix ${MATRIX_DIR}/${bsize}/${RES_FILE_NAME}_${bsize}_G2"
		    exec_cmd $cmd >> ${ldir}/build_raw_maps.log  2>&1	    
		else
		    cmd="cat ${DATA_DIR}/${RES_FILE_NAME}/${RES_FILE_NAME}_ontarget.allValidPairs | ${SCRIPTS}/build_matrix --matrix-format ${MATRIX_FORMAT} ${bsize_opts} --chrsizes $GENOME_SIZE_FILE --ifile /dev/stdin --oprefix ${MATRIX_DIR}/${bsize}/${RES_FILE_NAME}_${bsize} --matrix-format ${MATRIX_FORMAT}"
		    exec_cmd $cmd >> ${ldir}/build_raw_maps.log  2>&1
		fi
		
	    ## Build Allele-specific contact maps if specified
	    elif [[ ! -z ${ALLELE_SPECIFIC_SNP} ]]; then
	    	cmd="cat ${DATA_DIR}/${RES_FILE_NAME}/${RES_FILE_NAME}_G1.allValidPairs | ${SCRIPTS}/build_matrix --matrix-format ${MATRIX_FORMAT} ${bsize_opts} --chrsizes $GENOME_SIZE_FILE --ifile /dev/stdin --oprefix ${MATRIX_DIR}/${bsize}/${RES_FILE_NAME}_${bsize}_G1"
		exec_cmd $cmd >> ${ldir}/build_raw_maps.log 2>&1
		cmd="cat ${DATA_DIR}/${RES_FILE_NAME}/${RES_FILE_NAME}_G2.allValidPairs | ${SCRIPTS}/build_matrix --matrix-format ${MATRIX_FORMAT} ${bsize_opts} --chrsizes $GENOME_SIZE_FILE --ifile /dev/stdin --oprefix ${MATRIX_DIR}/${bsize}/${RES_FILE_NAME}_${bsize}_G2"
		exec_cmd $cmd >> ${ldir}/build_raw_maps.log  2>&1
		
	    else
		## Build normal diploid maps
		cmd="cat ${DATA_DIR}/${RES_FILE_NAME}/${RES_FILE_NAME}.allValidPairs | ${SCRIPTS}/build_matrix ${bsize_opts} --chrsizes $GENOME_SIZE_FILE --ifile /dev/stdin --oprefix ${MATRIX_DIR}/${bsize}/${RES_FILE_NAME}_${bsize} --matrix-format ${MATRIX_FORMAT}"
		exec_cmd $cmd >> ${ldir}/build_raw_maps.log  2>&1
	    fi
	done
    fi
    wait
done
