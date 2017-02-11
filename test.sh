#!/bin/bash

# AutoGrader for Assignment 2
# Generate a random file.
# Compute its md5sum
# Run the user program to copy the file
# Compare the md5sum of the file and its copy

userDomain="hk.ust.comp4651"
dummyFile="dummy"

# Clean up
clean_up() {
	rm -f $dummyFile
	rm -f md5.txt
	hadoop fs -rm -f $dummyFile
}

clean_up
# Generate a random file
head -c 10M < /dev/urandom > $dummyFile
md5sum $dummyFile > md5.txt

# Compile and package to jar
mvn clean package
if [ "$?" -ne 0 ]; then
	echo "[ERROR] mvn clean package UNSUCCESSFUL!" >> error
	clean_up
	exit 1
fi

# Copy the local file to HDFS
hadoop fs -moveFromLocal $dummyFile ./
if [ "$?" -ne 0 ]; then
	echo "[ERROR] Cannot move a test data to HDFS!" >> error
	clean_up
	exit 1
fi

# Run the user program to copy the file from HDFS back to local disk
hadoop jar target/FileSystemAPI-1.0-SNAPSHOT.jar $userDomain.CopyFile $dummyFile $dummyFile
if [ ! -f $dummyFile ]; then
	echo "[ERROR] No file has been copied from HDFS!" >> error
	clean_up
	exit 1
fi

md5sum -c md5.txt
if [ "$?" -ne 0 ]; then
	echo "[ERROR] Faild to pass the md5sum check!" >> error
	clean_up
	exit 1
fi

clean_up
echo "[SUCCESS]"
exit 0
