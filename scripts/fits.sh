#!/bin/sh

# FITS
HOME_DIR=$1

if [ -f "$HOME_DIR/pcdm-workshop/install/configs/variables" ]; then
  . "$HOME_DIR"/pcdm-workshop/install/configs/variables
fi

DOWNLOAD_URL="http://projects.iq.harvard.edu/files/fits/files/fits-${FITS_VERSION}.zip"
cd $DOWNLOAD_DIR
sudo curl $DOWNLOAD_URL > fits.zip
unzip fits.zip
chmod a+x fits-$FITS_VERSION/*.sh
cd fits-$FITS_VERSION/
sudo mv *.properties *.sh lib tools xml /usr/local/bin
