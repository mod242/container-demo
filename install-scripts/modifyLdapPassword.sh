#!/bin/bash
#
# Licensed Materials - Property of IBM
# 5747-SM3
# (c) Copyright IBM Corp. 2017, 2021  All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
echo "=========================================="
date
echo "Begin to modify LDAP password to the user provided value instead of the default value"

function modifyLDAPPassword(){
	ldappasswd -H ldap:/// -x -D "cn=admin,dc=ecm,dc=ibm,dc=com" -w $GLOBAL_PASSWORD -a $GLOBAL_PASSWORD -s $GLOBAL_PASSWORD
	if [ $? -eq 0 ] ;then
		echo "Root password changed successfully"
	else
        echo "Failed to change the admin password"
		exit_script
	fi

	users=$(ldapsearch -x -b 'dc=ecm,dc=ibm,dc=com' '(objectclass=person)' | grep dn)
	str=${users//dn:/ }
	echo "Resetting password for user: "
	for s in ${str[*]}
	do
		echo $s
		ldappasswd -H ldap:/// -x -D "cn=admin,dc=ecm,dc=ibm,dc=com" -w $GLOBAL_PASSWORD -s $GLOBAL_PASSWORD $s
	done
	echo "Done"
}

modifyLDAPPassword

if [ $? -eq 0 ] ;then
    echo "LDAP password modification finished successfully"
else
    exit_script
fi
