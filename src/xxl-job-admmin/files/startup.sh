#!/bin/bash
trap 'echo -e "WARN: receive Shutdown signal \nStopping xxl-job-admin [${PID}] ....." && kill -TERM $PID' TERM INT
. /opt/scripts/liblog.sh

export LANG=en_US.UTF-8
LOG_HOME=${WORKDIR}/logs
MaxRAMPercentage=${MAXRAMPERCENTAGE:-75.0}
MaxMetaspaceSize=${MAXMETASPACESIZE:-256M}
JMX_REMOTE_PORT=${JMX_REMOTE_PORT:-""}
APP_NAME=${APP_NAME:-example}
APPTYPE=${APPTYPE:-jar}
APPFILENAME=$(basename ./*.jar)
APPEXECNAME=${APP_NAME:-${APPFILENAME%.jar}}

current_path=${PWD}
case "$(uname)" in
  Linux)
    bin_abs_path=$(readlink -f $(dirname $0))
    ;;
  *)
    bin_abs_path=$(cd $(dirname $0); pwd)
    ;;
esac

base=${bin_abs_path}/..
export BASE=$base
xxl_conf=$base/application.properties

init_env(){
#  JAVA_HEAP_OPTS="-Xms${JAVA_XMS} -Xmx${JAVA_XMX}"
  JAVA_HEAP_OPTS="-XX:MaxRAMPercentage=${MaxRAMPercentage} -Xss512K -XX:MetaspaceSize=${MaxMetaspaceSize} -XX:MaxMetaspaceSize=${MaxMetaspaceSize}"

  #JVM OPTS
  # Which java to use
  [[ -z ${JAVA_HOME} ]] && JAVA="java" || JAVA="${JAVA_HOME}/bin/java"
  if [[ ! -f ${JAVA_HOME}/bin/${APPEXECNAME} ]]; then
    ln -s ${JAVA_HOME}/bin/java ${JAVA_HOME}/bin/${APPEXECNAME}
  fi
  JAVA=${JAVA_HOME}/bin/${APPEXECNAME}

  if [[ ! -d $LOG_HOME ]]; then
    mkdir $LOG_HOME
  fi
  # Generic jvm settings you want to add
  [[ -z ${CUSTOM_JAVA_OPTS} ]] && CUSTOM_JAVA_OPTS=""
  # Memory options
  [[ -z ${JAVA_HEAP_OPTS} ]] && JAVA_HEAP_OPTS="-Xms512M -Xmx512M"
  # JVM performance options
  if [[ -z ${JVM_PERFORMANCE_OPTS} ]]; then
      JVM_PERFORMANCE_OPTS="-server -XX:+UseG1GC -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35 -XX:+DisableExplicitGC -Djava.awt.headless=true"
  fi

  #JMX Settings
  # JMX port to use
  if [[ ! -z ${JMX_REMOTE_PORT} ]]; then
      JMX_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false \
      -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=${APPIP} -XX:+UnlockCommercialFeatures -XX:+FlightRecorder"
      JMX_OPTS="-Dcom.sun.management.jmxremote.port=${JMX_REMOTE_PORT} -Dcom.sun.management.jmxremote.rmi.port=${JMX_REMOTE_PORT} ${JMX_OPTS}"
  fi
  #spring log options
  SPRINGBOOT_OPTS=''
  SPRING_LOG_HOME="${LOG_HOME}"
  SPRING_LOG_FILE="${LOG_HOME}/${APP_NAME}_spring.log"
  if [[ "x${SPRING_LOG}" == "xtrue" ]]; then
      SPRINGBOOT_OPTS=" --logging.path=${SPRING_LOG_HOME} --logging.file=${SPRING_LOG_FILE}"
  fi
  # GC options
  GC_FILE_SUFFIX="-gc-$(date '+%F_%H-%M-%S').log"
  GC_LOG_FILE_NAME=""
  if [[ "x${GC_LOG_DISABLED}" != "xtrue" ]]; then
      GC_LOG_FILE_NAME=${APP_NAME}${GC_FILE_SUFFIX}
      GC_LOG_OPTS="-Xlog:gc*:file=${LOG_HOME}/${GC_LOG_FILE_NAME}:tags,time,uptime,level:filecount=5:filesize=5M"
  fi
  # Debug Options
  if [[ "x${JAVA_DEBUG}" == "xtrue" && ! -z "${JAVA_DEBUG_PORT}" ]]; then
      JAVA_DEBUG_OPTS="${JAVA_DEBUG_OPTS} -Xdebug -Xnoagent -Djava.compiler=NONE \
      -Xrunjdwp:transport=dt_socket,address=${JAVA_DEBUG_PORT},server=y,suspend=n"
  fi
  # Other options
  OTHER_JAVA_OPTS="-Dfile.encoding=UTF-8 -XX:+HeapDumpOnOutOfMemoryError \
  -XX:HeapDumpPath=${LOG_HOME}/$(date +'%H%M%S')_java_HeapDump.hprof"

  JAVA_OPTS="${JAVA_HEAP_OPTS} ${JVM_PERFORMANCE_OPTS} ${JMX_OPTS} \
  ${GC_LOG_OPTS} ${JAVA_DEBUG_OPTS} ${OTHER_JAVA_OPTS} ${CUSTOM_JAVA_OPTS}"
}
init_env

function get_PID() {
  echo -n $(ps -ef | grep -P "${APPFILENAME}\s" | awk '{print $2}')
}

function get_current_time(){
  echo -n $(date +'%Y-%b-%d %H:%M:%S.%3N [run.sh]')
}

function start_app() {
  if [[ -n $(get_PID) ]]; then
    warn "$APP_NAME is already started."
  else
    info "$(get_current_time) Starting $APP_NAME ...."
    info "$(get_current_time) console log path -> $CONSOLE_LOGPATH"
    bash -c "$JAVA $JAVA_OPTS -jar ${WORKDIR%/}/${APPFILENAME} $SPRING_BOOTSTRAP_OPTS_CLI" &
    PID=$!
    info "$(get_current_time) PID: $PID"
    wait $PID
  fi
}

function stop_app() {
  STOP_TIMEOUT=30
  if [[ -n $(get_PID) ]]; then
    info "Stopping $APP_NAME ...."
    kill $(get_PID)
    sleep 10
  fi
  if [[ -z $(get_PID) ]]; then
    info "Stopped $APP_NAME."
  else
    error "Cannot stop $(get_PID) $APP_NAME process..."
  fi
}

function usage() {
  echo "Usage: start.sh <start|stop|restart|get_pid>"
}

case "$1" in
	start)
		start_app
		;;
	stop)
		stop_app
		;;
	restart)
		stop_app
		start_app
		;;
	get_pid)
		get_PID
		;;
  *)
    usage
    ;;
esac