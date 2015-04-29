#!/bin/bash
# Script for to get machine information before doing the experiment

set +e # Dont fail fast since some information is maybe not available

title="Experiment results"
starpu_build=""
host="$(hostname | sed 's/[0-9]*//g' | cut -d'.' -f1)"
help_script()
{
    cat << EOF
Usage: $0 [options] outputfile.org

Script for to get machine information before doing the experiment

OPTIONS:
   -h      Show this message
   -t      Title of the output file
   -s      Path to the StarPU installation
EOF
}
# Parsing options
while getopts "t:s:h" opt; do
    case $opt in
	t)
	    title="$OPTARG"
	    ;;
	s)
	    starpu_build="$OPTARG"
	    ;;
	h)
	    help_script
	    exit 4
	    ;;
	\?)
	    echo "Invalid option: -$OPTARG"
	    help_script
	    exit 3
	    ;;
    esac
done

shift $((OPTIND - 1))
info=$1
if [[ $# != 1 ]]; then
    echo 'ERROR!'
    help_script
    exit 2
fi
#starpu_src="$starpu_build/.."

##################################################
# Preambule of the output file
echo "#+TITLE: $title" > $info
echo "#+DATE: $(eval date)" >> $info
echo "#+AUTHOR: $(eval whoami)" >> $info
echo "#+MACHINE: $(eval hostname)" >> $info
echo "#+FILE: $info" >> $info
echo " " >> $info 

##################################################
# Collecting metadata
echo "* MACHINE INFO" >> $info

echo "** PEOPLE LOGGED WHEN EXPERIMENT STARTED" >> $info
echo "#+BEGIN_EXAMPLE" >> $info    
who >> $info
echo "#+END_EXAMPLE" >> $info

echo "** ENVIRONMENT VARIABLES" >> $info
echo "#+BEGIN_EXAMPLE" >> $info    
env >> $info
echo "#+END_EXAMPLE" >> $info

echo "** HOSTNAME" >> $info
echo "#+BEGIN_EXAMPLE" >> $info    
hostname >> $info
echo "#+END_EXAMPLE" >> $info

if [[ -n $(command -v lstopo) ]];
then
    echo "** HWLOC MEMORY HIERARCHY" >> $info
    echo "#+BEGIN_EXAMPLE" >> $info    
    lstopo --of console >> $info
    echo "#+END_EXAMPLE" >> $info
fi

#if [[ -n "$starpu_build" ]]; 
#then
#    echo "** STARPU MACHINE DISPLAY" >> $info
#    echo "#+BEGIN_EXAMPLE" >> $info    
#    $starpu_build/tools/starpu_machine_display 1> tmp 2> /dev/null
#    cat tmp >> $info
#    rm -f tmp
#    echo "#+END_EXAMPLE" >> $info
#fi

if [ -f /proc/cpuinfo ];
then
    echo "** CPU INFO" >> $info
    echo "#+BEGIN_EXAMPLE" >> $info    
    cat /proc/cpuinfo >> $info
    echo "#+END_EXAMPLE" >> $info
fi

if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ];
then
    echo "** CPU GOVERNOR" >> $info
    echo "#+BEGIN_EXAMPLE" >> $info    
    cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor >> $info
    echo "#+END_EXAMPLE" >> $info
fi

if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq ];
then
    echo "** CPU FREQUENCY" >> $info
    echo "#+BEGIN_EXAMPLE" >> $info    
    cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq >> $info
    echo "#+END_EXAMPLE" >> $info
fi


#if [[ -n $(command -v nvidia-smi) ]];
#then
#    echo "** GPU INFO FROM NVIDIA-SMI" >> $info
#    echo "#+BEGIN_EXAMPLE" >> $info    
#    nvidia-smi -q >> $info
#    echo "#+END_EXAMPLE" >> $info
#fi 

if [ -f /proc/version ];
then
    echo "** LINUX AND GCC VERSIONS" >> $info
    echo "#+BEGIN_EXAMPLE" >> $info    
    cat /proc/version >> $info
    echo "#+END_EXAMPLE" >> $info
fi

if [[ -n $(command -v module) ]];
then
    echo "** MODULES" >> $info
    echo "#+BEGIN_EXAMPLE" >> $info    
    module list 2>> $info
    echo "#+END_EXAMPLE" >> $info
fi



##################################################
#TODO for Ondes3D
# Collecting revisions info 
echo "* CODE REVISIONS" >> $info
git_exists=`git rev-parse --is-inside-work-tree`
if [ "${git_exists}" ]
then
    echo "** GIT REVISION OF REPOSITORY" >> $info
    echo "#+BEGIN_EXAMPLE" >> $info    
    git log -1 >> $info
    echo "#+END_EXAMPLE" >> $info
fi
#
#svn_exists=`svn info . 2> /dev/null`
#if [ -n "${svn_exists}" ]
#then
#   echo "** SVN REVISION OF REPOSITORY" >> $info
#   echo "#+BEGIN_EXAMPLE" >> $info    
#   svn info >> $info
#   echo "#+END_EXAMPLE" >> $info
#fi

##################################################
# Part specific to the StarPU 
#if [[ -n "$starpu_build" ]]; 
#then
#    echo "** SVN REVISION OF ORIGINAL STARPU CODE" >> $info
#    echo "#+BEGIN_EXAMPLE" >> $info    
#    svn info $starpu_src >> $info    
#    echo "#+END_EXAMPLE" >> $info    
#fi

##################################################

#echo "* Charm++ building" >> $info
#echo "** Charm++" >> $info
#echo "*** Build command" >> $info
#echo './build charm++ mpi-linux-x86_64 --enable-tracing --enable-debugging -j16 -thread context' >> $info
#./build charm++ mpi-linux-x86_64 --enable-tracing --enable-debugging -j16 -thread context >> $info 2>&1
#echo "** Tau tracing support" >> $info
#echo "*** Build command" >> $info
#echo './build Tau mpi-linux-x86_64 --tau-makefile=/home/rktesser/myprefix/x86_64/lib/Makefile.tau-mpi-pdt -j16' >> $info
#./build Tau mpi-linux-x86_64 --tau-makefile=/home/rktesser/myprefix/x86_64/lib/Makefile.tau-mpi-pdt -j16 >> $info 2>&1
#echo "** AMPI" >> $info
#echo "*** Build command" >> $info
#echo './build AMPI mpi-linux-x86_64 --enable-tracing --enable-debugging -j16 -thread context' >> $info
#./build AMPI mpi-linux-x86_64 --enable-tracing --enable-debugging -j16 -thread context >> $info 2>&1

#Compilation information
echo "* Ondes3D" >> $info
echo "** Makefile" >> $info
echo "#+BEGIN_EXAMPLE" >> $info    
cat Makefile >> $info
echo "#+END_EXAMPLE" >> $info    

if [ -f tau-options.sh ]; then
	echo "** tau-options.sh" >> $info
	echo "#+BEGIN_EXAMPLE" >> $info    
	cat tau-options.sh >> $info
	echo "#+END_EXAMPLE" >> $info    
fi
if [ -f compile-tau.sh ]; then
	echo "** compile-tau.sh" >> $info
	echo "#+BEGIN_EXAMPLE" >> $info    
	cat compile-tau.sh >> $info
	echo "#+END_EXAMPLE" >> $info    
fi
if [ -f runtrace.sh ]; then
	echo "** runtrace.sh" >>$info
	echo "#+BEGIN_EXAMPLE" >> $info    
	cat runtrace.sh >> $info
	echo "#+END_EXAMPLE" >> $info    
fi

make clean > /dev/null 2>&1
if [ -f compile-tau.sh ]; then
	echo "** Compilation output" >> $info
	echo "#+BEGIN_EXAMPLE" >> $info    
	./compile-tau.sh >> $info 2>&1
	echo "#+END_EXAMPLE" >> $info
else
	make >> $info 2>&1
fi



