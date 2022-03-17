#Access the file refered and create groups and users
#!/bin/bash/
dataFile=$1
echo "creating groups and users from [$dataFile]"
if [[ "$dataFile" == "" ]]; then 
	echo "File name not provided"
else
	readData=$(cut -d: -f 4 $dataFile)
	iGroupsAdded=0
	# Go through this data file, ignore header row and iterate all users
	# first create groups and then create users and associate each user
	# to its appropriate groups
	groupName=""
	for groupName in $readData; do
		if [[ "$groupName" != "group" ]]; then 
			# Test if this group already exists or not
			grep -q $groupName /etc/group
			groupExists=$?
			if [[ "$groupExists" == 0 ]]; then
				echo "group $groupName already exists "
			else
				echo "Creating Group name $groupName"
				# now create this group in the system
				$(sudo groupadd $groupName)
				groupCreated=$?
				if [[ "$groupCreated" == 0 ]]; then 
					iGroupsAdded=$((iGroupsAdded+1))
				fi
			fi
		fi
	done

	echo "A total of $iGroupsAdded groups added to the system successfully"

	# Now go through the file again and add users and add them to the groups
	# they belong to. All groups should have already been created or they 
	# already exist in the system

	iUsersAdded=0
	while read line; do
		userName=$(cut -d: -f 1 <<< "$line")
		if [[ "$userName" != "group" ]]; then 
			password=$(cut -d: -f 2 <<< "$line")
			comments=$(cut -d: -f 3 <<< "$line")
			groupTo=$(cut -d: -f 4 <<< "$line")
			
			# see if the user exists in the system or not

			grep -q $userName /etc/passwd
			userExists=$?
			if [[ "$userExists" == 0 ]]; then
				echo "User name $userName already exists in the system"
			else
				# now create each user if it is not a header line
				$(sudo useradd $userName -p $password -c $comments)
				userCreated=$?
				if [[ "$userCreated" == 0 ]]; then 
					# now add this user to the group
					$(sudo usermod -a -G $groupTo $userName)
					iUsersAdded=$((iUsersAdded+1))
				fi
			fi
		fi #not a header line in the text file
	done < $dataFile

	echo "A total of $iUsersAdded users were added to the system"
fi
