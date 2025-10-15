#!/bin/bash
#
# Licensed Materials - Property of IBM
# 5747-SM3
# (c) Copyright IBM Corp. 2017, 2021  All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
echo "=========================================="
date
echo "Add users to the OpenLDAP server"

function addLdapUsers() {
    docker exec -i ldap bash <<EOF
    echo "$LDAP_LDIF">/tmp/ecm.ldif
    echo "$LDAP_ACL">/tmp/ecm_acc.ldif
    ldapadd -x -D "cn=admin,$LDAP_BASE_DN" -w $GLOBAL_PASSWORD -f /tmp/ecm.ldif
    ldapmodify -Y EXTERNAL -Q -H ldapi:/// -f /tmp/ecm_acc.ldif
    rm -f /tmp/ecm.ldif
EOF

	if [ $? -eq 0 ] ;then
		echo "LDAP users successfully added"
	else
        echo "Failed to add LDAP users"
		exit_script
	fi
}

addLdapUsers

if [ $? -eq 0 ] ; then
    echo "Add LDAP users completed successfully"
else
    exit_script
fi
