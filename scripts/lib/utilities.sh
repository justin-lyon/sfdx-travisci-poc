disable_error_trapping () {
  set +e # turn off error-trapping
}

contains () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

handle_error () {
  RETURN_CODE=$?

  if [ $RETURN_CODE -eq 1 ]; then
    echo ${1:-"Error with status code $RETURN_CODE"}
    exit 1 # force pipeline to fail
  fi

  set -e # turn on error-trapping
}

prompt_string () {
  read -p "$@: " STRING_INPUT
  echo $STRING_INPUT
}

rm_dir () {
  echo "*** Deleting directory $1"
  rm -rf $1
}

has_files () {
  FILES=$1
  if [ -z "$FILES" ]
    then
      return 1
    else
      return 0
  fi
}

build_incremental_dir () {
  disable_error_trapping

  LOG_FILE=${1:-logs/git-diff.log}
  INCREMENTAL_DIR=${2:incremental}
  mkdir -p $INCREMENTAL_DIR

  # Store Unique File Names and their dirnames
  FILES=$(cat $LOG_FILE | grep '^force-app*' | sort --unique)

  # Exit if no differences are found.
  if  has_files $FILES
    then

      FOLDERS=$(dirname $FILES | sort --unique)

      # STANDARD FILES ARE ANY THAT DO NOT NEED SPECIAL HANDLING
      STANDARD_FILES=$(cat $LOG_FILE | grep '^force-app*' | grep -v '\>\.cls' | grep -v '\>\.page' | grep -v 'lwc' | grep -v 'aura' | grep -v 'staticresources' | sort --unique)
      # BUNDLES ARE BOTH AURA AND LWC LIGHTNING COMPONENTS
      BUNDLES=$(cat $LOG_FILE | grep '^force-app*' | grep 'lwc\|aura' | sort --unique)

      # CAPTURE STATIC RESOURCES, RAW AND BUNDLED
      STATIC_RESOURCES=$(cat $LOG_FILE | grep '^force-app*' | grep 'staticresources' | grep -v 'meta.xml' | sort --unique )
      if has_files $STATIC_RESOURCES
        then
          PACKAGABLE_SR=()

          for i in $STATIC_RESOURCES
            do
              PARENT_DIR=$(basename $(dirname $i))
              ISRAW=$(expr "${PARENT_DIR}" == "staticresources")

              BUNDLED_SR_NAME=$(echo $i | cut -d'/' -f1-5)
              contains $BUNDLED_SR_NAME $PACKAGABLE_SR
              ALREADY_ADDED=$?

              if [ $ISRAW -eq 1 ]
              then
                # echo this is a raw static resource
                PACKAGABLE_SR+=("$i")
                METAFILE="$(echo $i | cut -d'.' -f1).resource-meta.xml"
                PACKAGABLE_SR+=("$METAFILE")
              elif [ $ALREADY_ADDED -eq 1 ]
              then
                # echo $BUNDLED_SR_NAME is a bundled static resource
                PACKAGABLE_SR+=("$BUNDLED_SR_NAME")
                METAFILE="$BUNDLED_SR_NAME.resource-meta.xml"
                PACKAGABLE_SR+=("$METAFILE")
              fi
            done

          cp ${PACKAGABLE_SR[@]} --parents -R -t $INCREMENTAL_DIR
      fi

      # CAPTURE VISUALFORCE PAGES
      VF_PAGES=$(cat $LOG_FILE | grep '^force-app*' | grep '\>\.page' | grep -v 'meta.xml' | sort --unique )
      if has_files $VF_PAGES
        then
          PACKAGABLE_VF=()
          for i in $VF_PAGES
            do
              PACKAGABLE_VF+=("$i")
              PACKAGABLE_VF+=("$i-meta.xml")
            done
          cp ${PACKAGABLE_VF[@]} --parents -t $INCREMENTAL_DIR
      fi
      # Get all Apex Classes, exluding their meta files - we'll make sure all meta files are included later.
      APEX_CLASSES=$(cat $LOG_FILE | grep '^force-app*' | grep '\>\.cls' | grep -v 'meta.xml' | sort --unique )
      if has_files $APEX_CLASSES
        then
          PACKAGABLE_APEX=()

          for i in $APEX_CLASSES;
            do
              PACKAGABLE_APEX+=($i)
              PACKAGABLE_APEX+=("$i-meta.xml")
            done

          cp ${PACKAGABLE_APEX[@]} --parents -t $INCREMENTAL_DIR
      fi

      if has_files $STANDARD_FILES
        then
          cp $STANDARD_FILES --parents -t $INCREMENTAL_DIR
      fi

      if has_files $BUNDLES
        then
          BUNDLE_FOLDERS=$(dirname $BUNDLES | sort --unique)
          cp $BUNDLE_FOLDERS --parents -t $INCREMENTAL_DIR
      fi
      # copy the files to the new incremental dir.
      # copy flat Apex and VF metadata
      # cp ${PACKAGABLE_APEX[@]} ${PACKAGABLE_VF[@]} --parents -t $INCREMENTAL_DIR
      # copy static resources, lwc, and aura components bundles completely.
      # cp $BUNDLE_FOLDERS ${PACKAGABLE_SR[@]} --parents -R -t $INCREMENTAL_DIR

    else
      echo
      echo
      echo "No File differences found. Exiting with status 0."
      exit 0
  fi


}
