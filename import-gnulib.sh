#! /bin/sh
#
# import-gnulib.sh -- imports a copy of gnulib into findutils
# Copyright (C) 2003,2004,2005,2006 Free Software Foundation, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,
# USA.
#
##########################################################################
#
# This script is intended to populate the "gnulib" directory
# with a subset of the gnulib code, as provided by "gnulib-tool".
#
# To use it, run this script, speficying the location of the
# gnulib code as the only argument.   Some sanity-checking is done
# before we commit to modifying things.   The gnulib code is placed
# in the "gnulib" subdirectory, which is where the buid files expect
# it to be.
#

# If CDPATH is set, it will sometimes print the name of the directory
# to which you have moved.  Unsetting CDPATH prevents this, as does
# prefixing it with ".".
unset CDPATH
configfile="./import-gnulib.config"
cvsdir="gnulib-cvs"

source $configfile

if [ -z "$gnulib_version" ] 
then
    echo "Error: There should be a gnulib_version setting in $configfile, but there is not." >&2
    exit 1
fi


if ! [ -d "$cvsdir" ] ; then	
    if mkdir "$cvsdir" ; then
	echo "Created $cvsdir"
    else
	echo "Failed to create $cvsdir" >&2
	exit 1
    fi
fi

# Decide if gnulib_version is probably a date or probably a tag.  
if date -d yesterday >/dev/null ; then
    # It looks like GNU date is available
    if date -d "$gnulib_version" >/dev/null ; then
	# Looks like a date.
	cvs_sticky_option="-D"
    else
	echo "Warning: assuming $gnulib_version is a CVS tag rather than a date" >&2
	cvs_sticky_option="-r"
    fi
else
	# GNU date unavailable, assume the version is a date
	cvs_sticky_option="-D"
fi



(
    # Change directory unconditionally (rater than  using checkout -d) so that
    # cvs does not pick up defaults from ./CVS.  Those defaults refer to our
    # own CVS repository for our code, not to gnulib.
    cd $cvsdir 
    if test -d gnulib/CVS ; then
	cd gnulib
	cmd=update
	root="" # use previous 
    else
	root="-d :pserver:anonymous@cvs.sv.gnu.org:/sources/gnulib"
	cmd=checkout
	args=gnulib
    fi
    set -x
    cvs -q -z3 $root  $cmd $cvs_sticky_option "$gnulib_version" $args
    set +x
)

set x $cvsdir/gnulib ; shift

if test -f "$1"/gnulib-tool
then
    true
else
    echo "$1/gnulib-tool does not exist, did you specify the right directory?" >&2
    exit 1
fi

if test -x "$1"/gnulib-tool
then
    true
else
    echo "$1/gnulib-tool is not executable" >&2
    exit 1
fi


if [ -d gnulib ]
then
    echo "Warning: directory gnulib already exists, removing it." >&2
    rm -rf gnulib
fi
mkdir gnulib

printf "Running gnulib-tool..."
if "$1"/gnulib-tool --import --dir=. --lib=libgnulib --source-base=gnulib/lib --m4-base=gnulib/m4  $modules
then
    : OK
else
    echo "gnulib-tool failed, exiting." >&2
    exit 1
fi
echo done



## for file in $extra_files; do
##   bn="$(basename $file)"
##   case "$file" in
##     */mdate-sh | */texinfo.tex) dest=doc; destfile=doc/"$bn";;
##     *) dest=.; destfile="$bn";;
##   esac
##   cmp "$file" "$destfile" || cp -fpv "$1"/"$file" "$dest" || exit 1
## done




cat > gnulib/Makefile.am <<EOF
# Copyright (C) 2004 Free Software Foundation, Inc.
#
# This file is free software, distributed under the terms of the GNU
# General Public License.  As a special exception to the GNU General
# Public License, this file may be distributed as part of a program
# that contains a configuration script generated by Automake, under
# the same distribution terms as the rest of that program.
#
# This file was generated by $0 $@.
#
SUBDIRS = lib
EOF


# Now regenerate things...
aclocal -I m4 -I gnulib/m4     &&     
autoheader                     &&     
autoconf                       &&     
automake --add-missing --copy  &&
echo Done.
