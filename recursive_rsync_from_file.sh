#!/bin/bash
##########################################################################################
# This shameful hack was developed by Stephen Buckley in Late July and early August 2013,
# and then modified to take input from a file by Josh Smith.
# It's got us out of some scrapes,
# hopefully it can help you copy lots of data elsewhere at speed too.
# 																		for Gruffyydd
##########################################################################################
# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Initialise some variables
NumRsyncProcs=0
RsyncApp=$(which rsync)
ParrallelRs=60

# Define some functions:

# function for getting number of running rsync processes

FuncRsyncProcs () {
	RsyncProcs=` ps -ax | grep "[r]sync " | nl | tail -n 1 | awk '{print $1}' `
	echo $RsyncProcs
}

# function for getting testing my oh so clever rsync proc test
FuncGrepTest() {
	GrepTest=` ps -ax | grep --color=auto "[r]sync " `
	echo $GrepTest
}

# function for getting major rsync version
FuncRsyncVers () {
	RsyncVers=` "$RsyncApp" --version | grep version |awk '{print $3}' |cut -d '.' -f 1 `
	echo $RsyncVers
}

# Create the required directory tree at the destnation
MakeDestDirs () {
    Dir=`dirname "$Item"`
    DestDir="$DestRoot"/"$Item"
    mkdir -p "$DestDir"
}

# function for background rsync of specified source and destination RsyncV2
V2sync () {
	BaseItem=`basename $Item`
	FilesLogFilePath=$LogRoot/${BaseItem}_Files.log
	LogFilePath=$LogRoot/$BaseItem.log
	ErrorsLogFilePath=$LogRoot/${BaseItem}_Errors.log
	if [[ -d ${Item} ]]
	then
	    MakeDestDirs
		Item=$Item/
		BaseItem=$BaseItem/
	fi
	$RsyncApp -WaE --log-file=$FilesLogFilePath --delete --stats -h $FullSourcePath $DestDir/$Item 1>> $LogFilePath 2>> $ErrorsLogFilePath &
}

# function for throttled version of  V2Sync
V2syncThrot () {
	while :
	do
		NumRsyncProcs=$(FuncRsyncProcs)
		GrepResult=$(FuncGrepTest)
		if [[ $NumRsyncProcs -le $ParrallelRs ]]
		then 
			echo "Launching rsync of $BaseItem"
			V2sync
			break
		else
			sleep 1
		fi
	done
}


# function for background rsync of specified source and destination RsyncV3
V3sync () {
    BaseItem=`basename $Item`
	FilesLogFilePath=$LogRoot/${BaseItem}_Files.log
	LogFilePath=$LogRoot/$BaseItem.log
	ErrorsLogFilePath=$LogRoot/${BaseItem}_Errors.log
	if [[ -d ${Item} ]]
	then
	    MakeDestDirs
		Item=$Item/
		BaseItem=$BaseItem/
	fi
	$RsyncApp -WaX --log-file=$FilesLogFilePath --delete --stats -h $FullSourcePath $DestDir/$Item 1>> $LogFilePath 2>> $ErrorsLogFilePath &
}

# function for throttled version of  V3Sync
V3syncThrot () {
	while :
	do
		NumRsyncProcs=$(FuncRsyncProcs)
		GrepResult=$(FuncGrepTest)
		if [[ $NumRsyncProcs -le $ParrallelRs ]]
		then 
			echo "Launching rsync of $BaseItem"
			V3sync
			break
		else
			sleep 1
		fi
	done
}	


##########################################################################################
RsyncVersResult=$(FuncRsyncVers)
echo "----------------------------------------------------------------------------"
echo "|                                                                           |"
echo "| You appear to be using $RsyncApp as your rsync varient.              |"
echo "| This binary is major release $RsyncVersResult                                            |"
echo "| Rsync version 3 is recomended if available, if you would like to use an   |"
echo "| alternative binary please enter the path now, otherwise press enter       |"
echo "| at the prompt to continue.                                                |"
echo "|                                                                           |"
echo "----------------------------------------------------------------------------"
read -e  -p "Path to alternative rsync binary (leave blank to keep default): " NewRsyncBinary

if [[ -n ${NewRsyncBinary} ]]
then
	RsyncApp=$NewRsyncBinary
fi

##########################################################################################
RsyncVersResult=$(FuncRsyncVers)

if [ $RsyncVersResult -eq 2 ]
then
	echo ""
	echo "----------------------------------------------------------------------------"
	echo "|                                                                           |"
	echo "| You will be prompted for the source, destination and log paths.           |"
	echo "| You will also be prompted for a number of concurrent rsyncs to run, the   |"
	echo "| default is 20, YMMV!                                                      |"
	echo "|                                                                           |"
	echo "| This script will iterate through the directory spawning an rsync for each |"
	echo "| item in the directory. Each item's rsync will be logged to a separate log |"
	echo "| file in the specified log directory.                                      |"
	echo "| rsync options will be -WaE --delete. ( man rsync for more details )       |"
	echo "|                                                     (rsync v2.x detected) |"
	echo "----------------------------------------------------------------------------"
else
	if [ $RsyncVersResult -ge 3 ]
	then
		echo ""
		echo "----------------------------------------------------------------------------"
		echo "|                                                                           |"
		echo "| You will be prompted for the source, destination and log paths.           |"
		echo "| You will also be prompted for a number of concurrent rsyncs to run, the   |"
		echo "| default is 20, YMMV!                                                      |"
		echo "|                                                                           |"
		echo "| This script will iterate through the directory spawning an rsync for each |"
		echo "| item in the directory. Each item's rsync will be logged to a separate log |"
		echo "| file in the specified log directory.                                      |"
		echo "| rsync options will be -WaX --delete ( man rsync for more details )        |"
		echo "|                                                   (rsync ≤ v3.x detected) |"
		echo "----------------------------------------------------------------------------"
	else
		echo "YOUR RSYNC IS EITHER NON EXISTANT OR LESS THAN v2"
		exit 1
	fi
fi
		

echo "Please enter the path to the file listing data to move…"
read -e -p "Path: " UncheckedPathsFile
echo ""
echo "Please enter the full path to the root folder containing paths you'd like to move..."
read -e -p "Path: " UncheckedSourceRoot
echo "Please enter the destination path…"
read -e -p "Path: " UncheckedDestRoot
echo "$UncheckedDestRoot"
echo ""
echo "Please enter the log path…"
read -e -p "Path: " UncheckedLogRoot
echo ""
echo "enter the number of rsync jobs you want in parallel."
read -e -p "Number of parallel rsyncs (leave blank for default of 20):" DesiredParrallelRs
echo""
echo "----------------------------------------------------------------------------"
echo ""




##########################################################################################
# Check that you are being fed directories.
# Convert source directory path into something nice for our for loop to chew on
##########################################################################################


# debugging
# set -x
# trap read debug

## Parse the paths file
echo ${UncheckedPathsFile}
if [[ -f ${UncheckedPathsFile} ]]
then
	PathsList=`cat $UncheckedPathsFile`
else
	if [[ -d  ${UncheckedPathsFile} ]]
	then
		echo "PATHS FILE IS A DIRECTORY NOT A FILE!"
		exit 1
	else
		if [[ ! -e ${UncheckedPathsFile} ]]
		then
			echo "PATHS FILE DOES NOT EXIST!"
			exit 1
		else
			echo "GOD ONLY KNOWS WHAT YOU ARE TRYING TO SYNC? BUT I AM HAVING NONE OF IT!"
			exit 1
		fi
	fi
fi


## Parse the destination

if [[ -d ${UncheckedSourceRoot} ]]
then
	SourceRoot=$UncheckedSourceRoot
else
	if [[ -f  ${UncheckedSourceRoot} ]]
	then
		echo "SOURCE ROOT $UncheckedSourceRoot IS A FILE NOT A DIRECTORY!"
		exit 1
	else
		if [[ ! -e  ${UncheckedSourceRoot} ]]
		then
			DestRoot="$UncheckedSourceRoot"
			echo "Source root doesn't exist! Sorry, bye."
            exit 1
		fi
	fi
fi

## Parse the destination

if [[ -d ${UncheckedDestRoot} ]]
then
	DestRoot=$UncheckedDestRoot
else
	if [[ -f  ${UncheckedDestRoot} ]]
	then
		echo "DESTINATION IS A FILE NOT A DIRECTORY!"
		exit 1
	else
		if [[ ! -e  ${UncheckedDestRoot} ]]
		then
			DestRoot="$UncheckedDestRoot"
			echo "Destination doesn't exist, creating $DestRoot"
			mkdir -v -m 777 -p "$DestRoot"
		fi
	fi
fi

## Parse the log destination

if [[ -d ${UncheckedLogRoot} ]]
then
	LogRoot=$UncheckedLogRoot
else
	if [[ -f  ${UncheckedLogRoot} ]]
	then
		echo "LOG DIR IS A FILE NOT A DIRECTORY!"
		exit 1
	fi
fi

## Set the number of parallel rsyncs

if [[ -z $DesiredParrallelRs ]]
then
	echo "Running the sync with the default of 20 rsyncs"
	echo ""
else
	if [[ $DesiredParrallelRs =~ ^-?[0-9]+$ ]]
	then
		ParrallelRs=$[DesiredParrallelRs * 3]
		echo "Running the sync with the requested $DesiredParrallelRs rsyncs"
		echo ""
	else
		echo "You haven't specified a number I've had enough bye!"
		exit 1
	fi
fi


##########################################################################################
# Some housekeeping WRT field separation, probably net strictly necessary in this context
# also, use basename to get the endpoints of each item path to be synced as we use this
# to synthesise some paths later on.
#
# Also, some checking for directories in order to ensure that we add trailing spaces to 
# directories only for avoidance of rsync cock-ups.
##########################################################################################


# Set inter field separator to new line only.
IFS=$'\n'

if [ $RsyncVersResult -eq 2 ]
then
	for Item in $SrcList
        do
        # Check the dir exists
            if [ ! -z $Item ]
            then
                FullSourcePath=$SourceRoot/$Item
                # If the path exists, move it
                if [ -e "$FullSourcePath" ]
                then
                    V2syncThrot
                else
                    echo "Could not sync $FullSourcePath as it does not exist"
                fi
            fi
        done
else
	if [ $RsyncVersResult -ge 3 ]
	then
	for Item in $SrcList
        do
        # Check the dir exists
            if [ ! -z $Item ]
            then
                FullSourcePath=$SourceRoot/$Item
                # If the path exists, move it
                if [ -e "$FullPath" ]
                then
                    V2syncThrot
                else
                    echo "Could not sync $FullSourcePath as it does not exist"
                fi
            fi
        done
	fi
fi


