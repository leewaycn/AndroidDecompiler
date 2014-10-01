#!/bin/sh

DOE="`dirname \"$0\"`"

function help
{
  echo "decompileAPK -- Decompiles an APK to have both the APK source and resources (XML
                , 9-patches,...) decompiled."
  echo ""
  echo "usage: decompileAPK.sh [options] <APK-file> [output-dir]"
  echo ""
  echo "options:"
  echo " -f,--format		Will format all Java files to be easier readable. 
  			 However, use with CAUTION! This option might change 
  			 line numbers!"
  echo " -p,--project		Will generate a Gradle-based Android project for you"
  echo " -h,--help		Prints this help message"
  echo ""
  echo "parameters:"
  echo " APK-file               The first parameter is required to be a valid APK file!"
  echo " Output Dir             The output directory is optional. If not set the
                         default will be used which is 'output' in the 
                         root of this tool directory."
}

#Init values
generateProject=false
formatJava=false

# Check all of the possible options
while [[ "$1" == -* ]]; do
    case $1 in
        -p | --project )        generateProject=true
                                ;;
        -f | --format )         formatJava=true
                                ;;
        -h | --help )           help
                                exit
                                ;;
    esac
    shift
done

# Read parameters
apkfile=$1
outputDir=$2

# Check a the minimum set of parameters is present. If not show help...
if [ -z $apkfile ]
then
  help
  exit
fi

# Check for the output directory. If not custom set, use the default
if [ -z $outputDir ]
then
    outputDir="$DOE/output"
else
    outputDir="$outputDir/output"
fi
resOutputDir="$outputDir/res-output"

echo "Decompiling APK file $apkfile"
echo "Results will be put in $outputDir"
echo ""

# Cleanup the output directories
echo "Cleaning up the output directories"
rm -Rf $DOE/output
rm -Rf $DOE/output-res
rm -Rf $outputDir
mkdir -p $outputDir

# Generate directories for project structure
if [[ "$generateProject" == true ]]; 
then 
	moduleName=app
	
	mkdir -p $outputDir/gradle
	mkdir -p $outputDir/gradle/wrapper
	mkdir -p $outputDir/$moduleName
	mkdir -p $outputDir/$moduleName/libs
	mkdir -p $outputDir/$moduleName/src
	mkdir -p $outputDir/$moduleName/src/main
	mkdir -p $outputDir/$moduleName/src/main/java
	
	baseOutputDir="$outputDir"
	resOutputDir="$outputDir/$moduleName/src/main/res-output"
	outputDir="$outputDir/$moduleName/src/main/java"
fi

# Create JAR from APK file, then decompile that JAR to have Java files
echo "Extracting JAR file from APK"
sh $DOE/dex2jar/d2j-dex2jar.sh -o $outputDir/output.jar $apkfile
echo "Decompiling JAR for Java files"
if [[ "$generateProject" == true ]]; 
then
	java -jar $DOE/jd-core-java/jd-core-java-1.2.jar $outputDir/output.jar $outputDir
else
	java -jar $DOE/jd-core-java/jd-core-java-1.2.jar $outputDir/output.jar $outputDir/src
fi
rm $outputDir/output.jar

# Extract all resources from the APK and remove all the unnecessary files from the output
echo "Extracting resources from APK file"
java -jar $DOE/apktool/apktool.jar decode -f $apkfile $resOutputDir
rm -Rf $resOutputDir/smali
rm $resOutputDir/apktool.yml

if [[ "$generateProject" == true ]]; 
then
	# Move the resource-output to correct project directory
	mv $resOutputDir/* $baseOutputDir/$moduleName/src/main/	
else
	# Move the resource-output to output directory
	mv $resOutputDir/* $outputDir
fi
rm -Rf $resOutputDir

if [[ "$generateProject" == true ]]; 
then
	cp $DOE/files/project/* $baseOutputDir/
	cp $DOE/files/wrapper/* $baseOutputDir/gradle/wrapper
	cp $DOE/files/module/* $baseOutputDir/$moduleName
fi

if [[ "$formatJava" == true ]]; 
then
	echo "Start formatting all Java files"
	$DOE/astyle/build/mac/bin/astyle -r -n -q --style=java -s4 -xc -S -K -j $outputDir/*.java
fi

exit;
