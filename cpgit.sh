#!/bin/sh

# All path MUST be ABSOLUTE

# This script will commit all regular file in $dir to git repository and may push it to Github

dir=$1
file=""
repo=~/.local/pboh/
remote=origin
branch=p
max_cache=1

check_result(){
# 	echo $1 if failed
#	echo $2 if succeed
	if [ $? != 0 ]
	then
		echo "$1"
		exit 1
	else
		echo "$2"
		exit 0
	fi
}

cd $repo
git status
if [ $? != 0 ]
then
	echo "No git repository found in $repo"
	return 1
fi
if [ "`git branch | grep -c "* $branch"`" != "1" ]
then
	git checkout $branch
	if [ $? != 0 ]
	then
		echo "No brantch named $branch"
		return 1
	fi
fi

add_file(){
#	year=`ls -l "$file" | sed 's/ \+/ /g' | cut -d" " -f8`
#	if [ `echo $year | grep -c ":"` = 1 ]
#	then
#		year=`date | cut -d" " -f6`
#	fi
#	month=`ls -l "$file" | sed 's/ \+/ /g' | cut -d" " -f6`
#	day=`ls -l "$file" | sed 's/ \+/ /g' | cut -d" " -f7`

	year=`stat "$file" | grep "Modify: " | cut -d" " -f2 | cut -b 1-4`
	month=`stat "$file" | grep "Modify: " | cut -d" " -f2 | cut -b 6-7`
	day=`stat "$file" | grep "Modify: " | cut -d" " -f2 | cut -b 9-10`
	time=`stat "$file" | grep "Modify: " | cut -d" " -f3 | cut -b 1-8`
#	size=`stat timers.c | grep "Size: " | cut -d" " -f 4`

	cd $repo

	if [ ! -d $year ]
	then
		mkdir $year
	fi
	cd $year
	if [ $? != 0 ]
	then
		echo "No dir named $year found"
		return 1
	fi

	if [ ! -d $month ]
	then
		mkdir $month
	fi
	cd $month
	if [ $? != 0 ]
	then
		echo "No dir named $month found"
		return 1
	fi

	if [ ! -d $day ]
	then
		mkdir $day
	fi
	cd $day
	if [ $? != 0 ]
	then
		echo "No dir named $day found"
		return 1
	fi

	cp -f "$file" ./"`basename "$file"`"_$time
	if [ $? != 0 ]
	then
		echo "Copy "$file" to $repo/$year/$month/$day/"$file" failed!"
		return 1
	fi
	return 0
}

error="0"

add(){
	file=$*
	add_file
	if [ $? != 0 ]
	then
		echo "Add "$file" to repository $repo failed"
		error="1"
	fi
}

#find $dir -type f -exec add '{}' \;
find $dir -type f | while read line
do
	add $line
done

if [ $error = "0" ]
then
	cd $repo
	git add .
	count=`git status | grep -E "new file:|deleted:|modified:" -c`
	if [ "$count" = "0" ]
	then
		echo "No file need to be commited"
		exit 0
	fi
	git commit -m "`date`"
	if [ $? != 0 ]
	then
		echo "Commit failed!"
		exit 1
	fi
	if [ $count -ge $max_cache ]
	then
		ping -c 1 github.com
		if [ $? != 0 ]
		then
			echo "Can't connect to Github.com"
			exit 1
		fi
		git push $remote $branch
		if [ $? != 0 ]
		then
			echo "Push to Github.com failed"
			exit 1
		else
			echo "Push to Github.com succeed"
			exit 0
		fi
	else
		echo "$count files(less than $max_cache) need to be committed, but ignore"
		exit 0
	fi
else
	echo "Some files failed to add to repository, please check it and try again"
	exit 1
fi

	
