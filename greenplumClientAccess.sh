#!/bin/sh


export PGPASSWORD="clickfox"

clientname=$1;
environment=$2;

usage()
{
        echo "Usage: greenplumClientAccess.sh <client> <environment>"
        echo "Example Connect: postgresClientAccess.sh comcast_mval mval"
        echo "List Clients: greenplumClientAccess.sh list"
        echo "JSON and Session Validation: greenplumClientAccess.sh <client> <environment> sjv <source_system> <YYYYMMDD> "
        echo "Example Validation: greenplumClientAccess.sh comcast prod sjv comcast-basettscr 20140505 "
        echo "Example Validation: greenplumClientAccess.sh comcast prod sjs comcast-basettscr 20140501 20140505"
exit 0
}
defaultEnv()
{
        environment='prod'
}

pgstatactivity()
{
        psql -U cf_$clientname -d $clientname -h $database -c "select usename, procpid, sess_id, waiting, datname, client_addr, substring(current_query,1,60) as Query,now()-query_start as Query_Time from pg_stat_activity  where current_query !='<IDLE>' order by query_start;"
}

if [ "$clientname" = "atos" ]
then
        statemachine=$(psql -At -U foxwatch -d db_overwatch -h hq-overwatch-prod.clickfox.net -c "select distinct MAX(statemachine) from client_info where clientname like '$clientname' and environment like '$environment'";)
else
statemachine=$(psql -At -U foxwatch -d db_overwatch -h hq-overwatch-prod.clickfox.net -c "select statemachine from client_info where overwatch_ic.client_info.id in (SELECT maxid.max FROM (SELECT overwatch_ic.client_info.clientname, overwatch_ic.client_info.environment, MAX(overwatch_ic.client_info.id) FROM overwatch_ic.client_info GROUP BY 1, 2) maxid) and clientname like '$clientname' and environment like '$environment'";)
fi

sjv()
{
#       statemachine=$(psql -At -U foxwatch -d db_overwatch -h hq-overwatch-prod.clickfox.net -c "select statemachine from client_info where overwatch_ic.client_info.id in (SELECT maxid.max FROM (SELECT overwatch_ic.client_info.clientname, overwatch_ic.client_info.environment, MAX(overwatch_ic.client_info.id) FROM overwatch_ic.client_info GROUP BY 1, 2) maxid) and clientname like '$clientname' and environment like '$environment'";)
#    datetime=$(echo ${datetime:0:4}-${datetime:4:2}-${datetime:6:2})
    dateid=$(psql -At -U cf_$clientname -d $clientname -h $statemachine -c "SELECT dateid FROM datetable WHERE datetime = '$datetime';")
    ssid=$(psql -At -U cf_$clientname -d $clientname -h $statemachine -c "SELECT sourcesystemid FROM sourcesystem WHERE name = '$sourcesystem';")

        echo "sr_session"
    psql -U cf_$clientname -d $clientname -h $database -c "select dateid,jobid,count(1) from sr_session where dateid=$dateid and sourcesystemid=$ssid group by 1,2 order by 1,2;"
        echo "sr_json_$ssid"
    psql -U cf_$clientname -d $clientname -h $database -c "select dateid,jobid,count(1) from sr_json_$ssid where dateid=$dateid and sourcesystemid=$ssid group by 1,2 order by 1,2;"
        echo "sr_sessionstats"
    psql -U cf_$clientname -d $clientname -h $database -c "select dateid,jobid,sourcesystemid,ceasourcesystem,cslidentifier,elements,elementscdds,sessions,sessionscdds,ts from sr_sessionstats where  ceasourcesystem='$sourcesystem' and cslidentifier='$datetime' or dateid=$dateid and sourcesystemid=$ssid order by 1,2;"

}

cdd()
{
 #       statemachine=$(psql -At -U foxwatch -d db_overwatch -h hq-overwatch-prod.clickfox.net -c "select statemachine from client_info where overwatch_ic.client_info.id in (SELECT maxid.max FROM (SELECT overwatch_ic.client_info.clientname, overwatch_ic.client_info.environment, MAX(overwatch_ic.client_info.id) FROM overwatch_ic.client_info GROUP BY 1, 2) maxid) and clientname like '$clientname' and environment like '$environment'";)
#    datetime=$(echo ${datetime:0:4}-${datetime:4:2}-${datetime:6:2})
    dateid=$(psql -At -U cf_$clientname -d $clientname -h $statemachine -c "SELECT dateid FROM datetable WHERE datetime = '$datetime';")
    ssid=$(psql -At -U cf_$clientname -d $clientname -h $statemachine -c "SELECT sourcesystemid FROM sourcesystem WHERE name = '$sourcesystem';")

                echo "sr_element"
    psql -U cf_$clientname -d $clientname -h $database -c "select dateid,jobid,count(1) from sr_element where dateid=$dateid and sourcesystemid=$ssid group by 1,2 order by 1,2;"
        echo "sr_elementcdd"
    psql -U cf_$clientname -d $clientname -h $database -c "select dateid,jobid,count(1) from sr_elementcdd where dateid=$dateid and sourcesystemid=$ssid group by 1,2 order by 1,2;"
        echo "sr_sessioncdd"
    psql -U cf_$clientname -d $clientname -h $database -c "select dateid,jobid,count(1) from sr_sessioncdd where dateid=$dateid and sourcesystemid=$ssid group by 1,2 order by 1,2;"

}
sjs()
{
 #statemachine=$(psql -At -U foxwatch -d db_overwatch -h hq-overwatch-prod.clickfox.net -c "select statemachine from client_info where overwatch_ic.client_info.id in (SELECT maxid.max FROM (SELECT overwatch_ic.client_info.clientname, overwatch_ic.client_info.environment, MAX(overwatch_ic.client_info.id) FROM overwatch_ic.client_info GROUP BY 1, 2) maxid) and clientname like '$clientname' and environment like '$environment'";)

ssid=$(psql -At -U cf_$clientname -d $clientname -h $statemachine -c "SELECT sourcesystemid FROM sourcesystem WHERE name = '$sourcesystem';")

echo "sr_sessionstats"
        psql -U cf_$clientname -d $clientname -h $database -c "select dateid,jobid,sourcesystemid,ceasourcesystem,cslidentifier,elements,elementscdds,sessions,sessionscdds,ts from sr_sessionstats where  ceasourcesystem='$sourcesystem' and cslidentifier between '$fdatetime' and '$ldatetime' or sourcesystemid=$ssid and dateid in (select dateid from datetable where datetime between '$fdatetime' and '$ldatetime') order by 1,2;"
}
outrange()
{
    dateid=$(psql -At -U cf_$clientname -d $clientname -h $statemachine -c "SELECT dateid FROM datetable WHERE datetime = '$datetime';")
    ssid=$(psql -At -U cf_$clientname -d $clientname -h $statemachine -c "SELECT sourcesystemid FROM sourcesystem WHERE name = '$sourcesystem';")
#outrange=$6


        range=`psql -At -U cf_$clientname -d $clientname -h $database -c "select json from sr_json_$ssid where dateid =$dateid  and json ~ '${oor}';"| sed -e 's/\",\"/\n/g' -e 's/\"\:\"/ /g'  |grep "\${oor}" |sed 's/[0-9]*//g'`
        result=`echo $range`
        echo -e "\033[1;41mSession cdd '${result}' has set as Integer which exceeds the integer limit.\033[0m"

psql  -U cf_$clientname -d $clientname -h $statemachine -c "select c.cddid,s.sourcesystemid,c.cddname,c.cdddatatypeid,cd.cdddatatypevalue from sm_sessioncdds s join cdd c on c.cddid=s.cddid join cdddatatype cd on c.cdddatatypeid=cd.cdddatatypeid where sourcesystemid=${ssid} and c.cddname='${result}';"

psql  -U cf_$clientname -d $clientname -h $database -c "select sessionid,dateid,jobid,objectuid from sr_json_${ssid} where dateid =$dateid    and json ~ '$oor';"


echo -e "\033[1;35mSending this case to DSM team to handle this.\033[0m"
 }
list()
{
        echo "psql -U cf_"$clientname" -d "$clientname" -h "$database
}

accessDB()
{
        psql -U cf_$clientname -d $clientname -h $database
}

[ -z "$1" ] && usage


[ -z "$2" ] && defaultEnv
[ "$1" = "-h" ] && usage


if [ "$clientname" = "atos" ]
then
        database=$(psql -At -U foxwatch -d db_overwatch -h hq-overwatch-prod.clickfox.net -c "select distinct MAX(repository) from client_info where clientname like '$clientname' and environment like '$environment'";)
else

database=$(psql -At -U foxwatch -d db_overwatch -h hq-overwatch-prod.clickfox.net -c "select repository from client_info where overwatch_ic.client_info.id in (SELECT maxid.max FROM (SELECT overwatch_ic.client_info.clientname, overwatch_ic.client_info.environment, MAX(overwatch_ic.client_info.id) FROM overwatch_ic.client_info GROUP BY 1, 2) maxid) and clientname like '$clientname' and environment like '$environment'";)
fi

[ -z "$3" ] && accessDB
[ "$3" = "pgsa" ] && pgstatactivity
[ "$3" = "list" ] && list
if [[ "$3" = "sjv" && -n "$4"  && -n "$5" ]]
then
        datetime="$5"
        sourcesystem="$4"
        sjv
elif [[ "$3" = "cdd" && -n "$4"  && -n "$5" ]]
then
        datetime="$5"
        sourcesystem="$4"
        cdd
elif [[ "$3" = "sjs" && -n "$4"  && -n "$5" && -n "$6" ]]
then
        fdatetime="$5"
        ldatetime="$6"
        sourcesystem="$4"
        sjs
elif [[ "$3" = "outrange" && -n "$4"  && -n "$5" && -n "$6" ]]
then
        datetime="$5"
        sourcesystem="$4"
        oor="$6"
          outrange
fi
