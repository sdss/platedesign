#!/usr/bin/python

"""
A script to retrieve the plPlugMap* files for a given run and convert
them from DOS linefeeds to unix. Creates a new directory for each platerun.

NOTE: If a directory already exists whose name is that of the platerun,
	  it will be overwritten!!
	  
Usage:

% get_plugmap_files.py <url1> <url2> ...
	  
Example:

% get_plugmap_files.py http://sdss.physics.nyu.edu/as2/drillruns/2009.03.a.marvels

Will create a directory called: "2009.03.a.marvels"

v1.0 23 March 2008 / Demitri Muna, NYU

"""

import os
import re
import sys
import urllib2
import string
import zipfile
import shutil

# --------------------------
username	  = "as2"
password 	  = "go2014"
# --------------------------

# ======================================================================
def url_request (url, username, password):


	request = urllib2.Request(url)
	
	if username != None:
		import base64
		header = 'Basic %s' % \
			base64.encodestring('%s:%s' % (username,password))[:-1]
		request.add_header('Authorization', header)
	
	return request
# Ref: http://www.redmountainsw.com/wordpress/archives/curl-python
# ======================================================================

# ======================================================================
def unzip_file_into_dir(file, dir):

    os.mkdir(dir, 0777)
    zfobj = zipfile.ZipFile(file)
    for name in zfobj.namelist():
        if name.endswith('/'):
            os.mkdir(os.path.join(dir, name))
        else:
            outfile = open(os.path.join(dir, name), 'wb')
            outfile.write(zfobj.read(name))
            outfile.close()
# Ref: http://lists.canonical.org/pipermail/kragen-hacks/2002-February/000322.html
# ======================================================================

urls = sys.argv[1:]
#urls = ["http://sdss.physics.nyu.edu/as2/drillruns/2009.03.a.marvels"]

if (len(urls) == 0):
	print "Usage: Please see file header."

for url in urls:
	
	# Strip trailing "/" from url if there is one
	if (url[-1] == '/'):
		url = url[0:-1]

	# Extract name of plate run (last part of url)
	platerun = url.split("/")[-1]
	
	# Create a new URL request object with authentication
	request = url_request(url, username, password)
		
	print url

	# -----------------
	# Retrieve web page
	# -----------------
	http_response = urllib2.urlopen(request)
	html_source = http_response.read() # returns one very long string
	html_source = html_source.split("\n") # split into lines
	
	# Find first line containing name of zip file
	for line in html_source:
		if (line.find(".zip") != -1):
			break

	# ------------------------------------------
	# Extract zip file name from the page source
	# ------------------------------------------
	match = re.search("[0-9\.a-z\-]+\.zip", line)
	if (match):
		zip_filename = line[match.start():match.end()]
	else:
		print "Could not find zip file for url: " + url
		break
	
	# Append name of zip file to the base URL.
	zip_file_url = url + "/" + zip_filename

	# Create a new http request with this URL.
	request = url_request(zip_file_url, username, password)
	http_response = urllib2.urlopen(request)

	# Make a new directory with same name minus the ".dos.zip"
	plate_files_dir = zip_filename.replace(".dos.zip", "")

	# Write to a new local file with the same name as the original file.
	output_file = open(zip_filename, 'w')
	output_file.write(http_response.read())	
	output_file.close()
	
	# If "plate_files_dir" exists, remove it.
	if os.path.exists(plate_files_dir):
		shutil.rmtree(plate_files_dir)
	
	zip_file = open(zip_filename, 'r')
	unzip_file_into_dir(zip_file, plate_files_dir) # this creates the output dir
	
	# delete downloaded zip file
	os.remove(zip_filename)
	
	# --------------------------------------------------------
	# Loop over all output files.
	# Only keep plPlugMap* files, delete the rest.
	# Convert the plPlugMap files from DOS to unix linefeeds.
	# --------------------------------------------------------
	for platefile in os.listdir(plate_files_dir):
		
		match = re.match("plPlugMapP", platefile)
		if (match):
			
			# convert linefeeds from DOS to unix
			# (might be better to test if these are DOS files first, but there it is)
			f     = open(plate_files_dir + "/" + platefile, 'r')
			f_tmp = open(plate_files_dir + "/" + platefile + ".tmp", 'w')
			
			# loop over each line, replace DOS (CRLF) with unix linefeeds
			for platefile_line in f:
				f_tmp.write(platefile_line.replace("\r\n", "\n"))
			
			f.close()
			f_tmp.close()
			
			# delete old (dos) file, rename new file
			os.remove(plate_files_dir + "/" + platefile)
			os.rename(plate_files_dir + "/" + platefile + ".tmp", \
				plate_files_dir + "/" + platefile)
			
		else:
			# not a plPlugMap file - delete
			os.remove(plate_files_dir + "/" + platefile)
