#!/bin/sh

# sanitise environment so all tools behave correctly
unset LC_ALL
unset LANG
LC_CTYPE="C"
LC_COLLATE="C"
LC_TIME="C"
LC_NUMERIC="C"
LC_MONETARY="C"
LC_MESSAGES="C"

MYTMP=/dev/NONEXISTANT

cleanup()
{
    echo "Removing ${MYTMP} ..."
    [ -d "${MYTMP}" ] && rm -r "${MYTMP}"
}

# catch interrupts and terms
trap 'cleanup' 0 1 2 3 15


# exit whenever a simple command returns non-zero
set -e

# error when reading from an undefined variable
set -u

# create MYTMP (THIS DOESNT WORK ON BSD AND MAC)
MYTMP=$(mktemp -d)

PROG="$1/lrcaller"
if [ ! -x "$PROG" ]; then
    echo "ERROR: lrcaller binary not found/executable." >&2
    echo "--------------------------------------" >&2
    exit 104
fi

DATADIR="/nfs/odinn/users/hannesha/data/DONOTMOVEME/lrcaller-test/"

case $2 in
    1) # /nfs/odinn/users/bjarnih/projects/ONT/210119/batch
#         PNS="1_1 1_2 1_3 1_4 1_5"
        PNS="1_5"
        CL='"${PROG}" -lsf 0.2 -w 100 -gtm ad
            -fa "/odinn/users/bjarnih/projects/ONT/210115/genome.fa"
            "${DATADIR}/BAM_LINKS/${PN}"
            "${DATADIR}/example.vcf"
            "${MYTMP}/${PN}.vcf"'
        ;;

    2a) # /nfs/odinn/users/bjarnih/projects/ONT/210115/commands_lsf0.2_w1300
        PNS="2a_1 2a_2"
        CL='"${PROG}" -lsf 0.2 -w 1300 -gtm multi
        -fa "/odinn/users/bjarnih/projects/ONT/210115/genome.fa"
        "${DATADIR}/BAM_LINKS/${PN}"
        "/nfs/odinn/users/bjarnih/projects/ONT/210115/PRDM9_alleles_19alleles.csv.vcf.gz"
        "${MYTMP}/${PN}.vcf"'
        ;;

    2b) # /nfs/odinn/users/bjarnih/projects/ONT/210115/commands_lsf0.2_w1300
        PNS="2b_1 2b_2"
        CL='"${PROG}" -lsf 0.2 -w 1300 -gtm multi
        -fa "/odinn/users/bjarnih/projects/ONT/210115/genome.fa"
        "${DATADIR}/BAM_LINKS/${PN}"
        "/nfs/odinn/users/bjarnih/projects/ONT/210115/PRDM9_alleles_12alleles.csv.vcf.gz"
        "${MYTMP}/${PN}.vcf"'
        ;;

    2c) # /nfs/odinn/users/bjarnih/projects/ONT/210115/commands_lsf0.2_w1300
        PNS="2c_1 2c_2"
        CL='"${PROG}" -lsf 0.2 -w 1300 -gtm multi -rb
        -fa "/odinn/users/bjarnih/projects/ONT/210115/genome.fa"
        "${DATADIR}/BAM_LINKS/${PN}"
        "/nfs/odinn/users/bjarnih/projects/ONT/210115/PRDM9_alleles_19alleles.csv.vcf.gz"
        "${MYTMP}/${PN}.vcf"'
        ;;

    *)
        echo "WRONG TEST IDENTIFIER!" >&2
        exit 77
esac

echo "Test $2 start."

mkdir -p "${MYTMP}"
for PN in $PNS; do
    eval $CL
done

echo "Test $2 end."

FAIL=0

for PN in $PNS; do
    cd "${MYTMP}"
    ACTUAL=$(openssl md5 ${PN}.vcf)

    cd "${DATADIR}/CONTROL"
    CONTROL=$(openssl md5 ${PN}.vcf)

    if [ "$CONTROL" != "$ACTUAL" ]; then
        echo "Output files are not as expected."
        echo "GOT:"
        echo "-------"
        echo "$ACTUAL"
        echo "-------"
        echo "EXPECTED:"
        echo "-------"
        echo "$CONTROL"
        echo "DIFF:"
        diff -u "${MYTMP}/${PN}.vcf" "${DATADIR}/CONTROL/${PN}.vcf"
        FAIL=1
    fi
done

exit $FAIL
