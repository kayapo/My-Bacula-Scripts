#!/bin/bash
set -e
BCKDIR="/var/backups/mysql"
EXTRAFILE="/etc/bacula/scripts/mysql.extra"

MYC="/usr/bin/mysql"
MYA="/usr/bin/mysqladmin"
MYD="/usr/bin/mysqldump"

[ -f "${BCKDIR}/.keepfile" ] || exit 1
case "$1" in
        pre)
                `${MYA} --defaults-extra-file=${EXTRAFILE} ping | grep -q '^mysqld is alive$'`
                [ "$?" == "0" ] && ${MYC} --defaults-extra-file=${EXTRAFILE} -BN -e "show databases;" | grep -v 'test\|lost+found\|information_schema\|msgindex' | while read db
                        do
                        # echo "Backup $db @ `date -R`"
                        [ -d "${BCKDIR}/${db}" ] || mkdir -m u=rwX,g=rwX,o=rX,g+s -p "${BCKDIR}/${db}"
                        ${MYD} --defaults-extra-file=${EXTRAFILE} -BN ${db} \
                                        --add-drop-database \
                                        --add-drop-table \
                                        --allow-keywords \
                                        --comments \
                                        --create-options \
                                        --no-data \
                                        --set-charset \
                                        --routines \
                                        --triggers \
                                        --quick \
                                        --no-data > "${BCKDIR}/${db}/${db}-create.sql"
                        ${MYC} --defaults-extra-file=${EXTRAFILE} -BN -e "use ${db}; show tables;" | while read tbl
                                do
                                ${MYD} --defaults-extra-file=${EXTRAFILE} -BN ${db} --tables ${tbl} \
                                                --no-create-info \
                                                --complete-insert \
                                                --extended-insert \
                                                --add-locks \
                                                --quick > "${BCKDIR}/${db}/${db}.${tbl}-data.sql"
                                done
                        done
        ;;
        post)
                find ${BCKDIR} -type f -name '*.sql' -exec rm {} \;
        ;;
esac

exit 0

