#!bash
chmod -R 775 *
git clone ssh://ralberts@132.253.10.121:29418/wc windchillRepo
cd windchillRepo
git checkout -b cainteg.x-20-mor origin/cainteg.x-20-mor
git submodule update --init
